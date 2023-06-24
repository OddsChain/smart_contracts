// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./libraries/DataTypes.sol";

import "@axelar/contracts/executable/AxelarExecutable.sol";
import "@axelar/contracts/interfaces/IAxelarGasService.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Odds is AxelarExecutable {
    //
    uint256 public singleBetIDCounter;

    uint256 public estimatedCrossChainGasAmount;

    uint256 public constant VALIDATOR_STAKE_AMOUNT = 1000 * 10 ** 18;
    uint256 public constant CLAIM_WINNING_WAIT_TIME = 300; // 300 seconds - 5 minutes
    uint256 public constant VALIDATOR_VOTE_TIME = 600; // 600 seconds - 10 minutes

    string public destinationChain = "Fantom";
    string public destinationAddress;

    uint256 validatorCount;

    address public oddsTokenAddress;
    address public deployer;

    address[] public validators;

    IAxelarGasService public immutable gasService;

    // STRUCTS

    struct User {
        uint256 totalWinnings;
        uint256 totalBetsParticipated;
        uint256 balance;
    }

    struct BetStatistics {
        uint256 yesPool;
        uint256 noPool;
        uint256 totalPool;
        uint256 yesPartcipants;
        uint256 noParticipants;
        uint256 yesOutcomeCount;
        uint256 noOutcomeCount;
    }

    struct Report {
        address reporter;
        address maliciousValidator;
        uint256 betId;
        string description;
        bool currentlyChallenged;
        uint256 voteTime;
        uint256 support; // 1
        uint256 oppose; // 2
        uint256 reportOutcome; // 0 - Nothing ||| 1 - Validator Was Right ||| 2 - Validator Was Wrong: Refunds Granted, Validator Losses Stake And Validation Rights
    }

    struct Bet {
        uint256 betID;
        string description;
        bool betType; // false - private validation || true - public validation
        address[] validators;
        address[] participants;
        address creator;
        uint256 betEndTime;
        uint256 outcome; // 1 - yes || 2 - no
        bool accepted; // if the bet can be participated in
        uint256 validationCount;
        uint256 claimWaitTime;
        uint256 toBeSetTime;
        BetStatistics betStatistics;
        Report betReport;
    }

    struct Validator {
        uint256 validatorId;
        address validator;
        uint256 betsRejected;
        uint256 betsAccepted;
        uint256 betsValidated;
        uint256 totalReports;
        uint256 balance;
    }

    //  MAPPINGS

    mapping(uint256 => Bet) public _singleBetDetails;

    mapping(address => mapping(uint256 => uint256)) public _userBetAmount;

    mapping(address => mapping(uint256 => bool)) public _userParticipation;

    mapping(address => mapping(uint256 => uint256)) public _userBetChoice;

    mapping(address => mapping(uint256 => bool)) public _singleBetClaimed;

    mapping(address => Validator) public _validators;

    mapping(address => bool) public _isValidator;

    mapping(address => mapping(uint256 => bool)) public _hasVoted;

    mapping(uint256 => mapping(address => bool)) public _refundClaimed;

    mapping(address => User) public _userDetails;

    mapping(address => bool) public _canValidate;

    mapping(address => mapping(uint256 => bool)) public _hasValidated;

    // EVENTS

    event SingleBet_Created(
        uint256 betID,
        string description,
        bool betType,
        uint256 betEndTime,
        address creator,
        address[] validators
    );

    event Bet_Joined(
        uint256 betID,
        uint256 amount,
        address user,
        uint256 yesPool,
        uint256 noPool,
        uint256 totalPool,
        uint256 yesParticipants,
        uint256 noParticipants
    );

    event BetWinnings_Claimed(uint256 betID, address user, uint256 winnings);

    // VALIDATOR EVENTS

    event Validator_Joined(address validator, uint256 validatorId);

    event Bet_Accepted(uint256 betID, bool choice, address validator);

    event Bet_Denied(uint256 betID, bool choice, address validator);

    event Bet_Validated(uint256 betID, uint256 outcome, address validator);

    event Bet_Refunded(uint256 betID, address user, uint256 refundAmount);

    event Validator_Reported(
        address reporter,
        address validator,
        string description,
        uint256 betID,
        uint256 voteTime
    );

    event Validator_Assigned(uint256 betID, bool betType, uint256 randomNumber);

    // CONSTRUCTOR
    constructor(
        address _gateway,
        address _gasReceiver,
        address _oddsTokenAddress,
        string memory _destinationAddress,
        uint256 _estimatedCrossChainGasAmount
    ) AxelarExecutable(_gateway) {
        gasService = IAxelarGasService(_gasReceiver);
        destinationAddress = _destinationAddress;
        oddsTokenAddress = _oddsTokenAddress;
        estimatedCrossChainGasAmount = _estimatedCrossChainGasAmount;
        deployer = msg.sender;
    }

    //  BET RELATED FUNCTIONS
    function createSingleBet(
        DataTypes.CreateSingleBetParams memory _createSingleBetParams
    ) public payable {
        singleBetIDCounter++;

        _singleBetDetails[singleBetIDCounter].betID = singleBetIDCounter;

        _singleBetDetails[singleBetIDCounter]
            .description = _createSingleBetParams.description;
        _singleBetDetails[singleBetIDCounter].betType = _createSingleBetParams
            .betType;

        _singleBetDetails[singleBetIDCounter].creator = msg.sender;

        if (_createSingleBetParams.betType) {
            require(msg.value >= estimatedCrossChainGasAmount, "#30");

            _getVRFForValidatorAssignment(
                _createSingleBetParams.betType,
                singleBetIDCounter,
                estimatedCrossChainGasAmount
            );

            // accepted
            _singleBetDetails[singleBetIDCounter].accepted = true;

            _singleBetDetails[singleBetIDCounter].toBeSetTime =
                _createSingleBetParams.betEndTime +
                block.timestamp;

            emit SingleBet_Created(
                singleBetIDCounter,
                _createSingleBetParams.description,
                _createSingleBetParams.betType,
                0,
                msg.sender,
                new address[](1)
            );
        } else {
            require(_createSingleBetParams.validators.length == 3, "#31");
            _singleBetDetails[singleBetIDCounter]
                .validators = _createSingleBetParams.validators;

            _singleBetDetails[singleBetIDCounter].betEndTime =
                _createSingleBetParams.betEndTime +
                block.timestamp;

            emit SingleBet_Created(
                singleBetIDCounter,
                _createSingleBetParams.description,
                _createSingleBetParams.betType,
                block.timestamp + _createSingleBetParams.betEndTime,
                msg.sender,
                _createSingleBetParams.validators
            );
        }
    }

    function joinSingleBet(
        uint256 _betID,
        uint256 _amount,
        uint256 _choice // 1 - yes || 2 - no
    ) public {
        uint256 betEndTime = _singleBetDetails[_betID].betEndTime;
        bool accepted = _singleBetDetails[_betID].accepted;

        require(_betID <= singleBetIDCounter, "#01");
        require(accepted, "#02");
        require(block.timestamp < betEndTime, "#03");
        require(!_userParticipation[msg.sender][_betID], "#07");
        require(_userDetails[msg.sender].balance >= _amount, "#32");

        _userDetails[msg.sender].balance -= _amount;
        _userDetails[msg.sender].totalBetsParticipated += 1;

        _userBetAmount[msg.sender][_betID] = _amount;
        _userParticipation[msg.sender][_betID] = true;

        // update the bet statistics

        _singleBetDetails[_betID].betStatistics.totalPool += _amount;
        _singleBetDetails[_betID].participants.push(msg.sender);

        if (_choice == 1) {
            _singleBetDetails[_betID].betStatistics.yesPool += _amount;
            _singleBetDetails[_betID].betStatistics.yesPartcipants += 1;
            _userBetChoice[msg.sender][_betID] = 1;
        }
        if (_choice == 2) {
            _singleBetDetails[_betID].betStatistics.noPool += _amount;
            _singleBetDetails[_betID].betStatistics.noParticipants += 1;
            _userBetChoice[msg.sender][_betID] = 2;
        }

        emit Bet_Joined(
            _betID,
            _amount,
            msg.sender,
            _singleBetDetails[_betID].betStatistics.yesPool,
            _singleBetDetails[_betID].betStatistics.noPool,
            _singleBetDetails[_betID].betStatistics.totalPool,
            _singleBetDetails[_betID].betStatistics.yesPartcipants,
            _singleBetDetails[_betID].betStatistics.noParticipants
        );
    }

    function claimSingleBetWinnings(uint256 _betID) public {
        uint256 userChoice = _userBetChoice[msg.sender][_betID];
        uint256 betOutcome = _singleBetDetails[_betID].outcome;

        require(_betID <= singleBetIDCounter, "#01");
        require(_userParticipation[msg.sender][_betID], "#06");
        require(!_singleBetClaimed[msg.sender][_betID], "#12");
        require(
            block.timestamp > _singleBetDetails[_betID].claimWaitTime,
            "#23"
        );
        require(betOutcome != 0, "#05");
        require(userChoice == betOutcome, "#08");
        require(
            !_singleBetDetails[_betID].betReport.currentlyChallenged,
            "#22"
        );
        require(_singleBetDetails[_betID].betReport.reportOutcome != 2, "#34");

        uint256 userBetAmount;
        uint256 winnersPool;
        uint256 loosersPool;
        uint256 userShareInReward;
        uint256 winnings;

        // YES
        if (betOutcome == 1) {
            userBetAmount = _userBetAmount[msg.sender][_betID];

            winnersPool = _singleBetDetails[_betID].betStatistics.yesPool;

            loosersPool =
                (_singleBetDetails[_betID].betStatistics.noPool * 90) /
                100;

            userShareInReward = (userBetAmount * 100) / winnersPool;
            winnings = (userShareInReward * loosersPool) / 100;
        }

        // NO
        if (_singleBetDetails[_betID].outcome == 2) {
            userBetAmount = _userBetAmount[msg.sender][_betID];

            winnersPool = _singleBetDetails[_betID].betStatistics.noPool;

            loosersPool =
                (_singleBetDetails[_betID].betStatistics.yesPool * 90) /
                100;

            userShareInReward = (userBetAmount * 100) / winnersPool;
            winnings = (userShareInReward * loosersPool) / 100;
        }

        _singleBetClaimed[msg.sender][_betID] = true;

        _userDetails[msg.sender].balance += winnings;
        _userDetails[msg.sender].totalWinnings += 1;

        emit BetWinnings_Claimed(_betID, msg.sender, winnings);
    }

    function claimBetRefund(uint256 _betID) public {
        require(_betID <= singleBetIDCounter, "#01");
        require(_userParticipation[msg.sender][_betID], "#06");
        require(_singleBetDetails[_betID].betReport.reportOutcome == 2, "#29");
        require(!_refundClaimed[_betID][msg.sender], "#28");

        _refundClaimed[_betID][msg.sender] = true;

        uint256 userBetAmount = _userBetAmount[msg.sender][_betID];

        _userDetails[msg.sender].balance += userBetAmount;

        emit Bet_Refunded(_betID, msg.sender, userBetAmount);
    }

    // VALIDATION RELATED FUNCTIONS

    function joinValidators() public {
        uint256 validatorBalance = IERC20(oddsTokenAddress).balanceOf(
            msg.sender
        );
        require(validatorBalance > VALIDATOR_STAKE_AMOUNT, "#14");
        require(!_isValidator[msg.sender], "#15");

        _validators[msg.sender].balance += VALIDATOR_STAKE_AMOUNT;
        _validators[msg.sender].validatorId = validatorCount;
        _validators[msg.sender].validator = msg.sender;

        validators.push(msg.sender);
        _canValidate[msg.sender] = true;

        _isValidator[msg.sender] = true;
        validatorCount++;

        emit Validator_Joined(msg.sender, validatorCount - 1);
    }

    function acceptOrDenyBet(uint256 _betID, bool _choice) public {
        require(_betID <= singleBetIDCounter, "#01");
        require(_singleBetDetails[_betID].betType, "#04");
        require(_isValidator[msg.sender], "#16");

        address requiredValidator = _singleBetDetails[_betID].validators[0];
        require(msg.sender == requiredValidator, "#17");

        _validators[msg.sender].betsAccepted += 1;

        _singleBetDetails[_betID].betEndTime =
            _singleBetDetails[_betID].toBeSetTime +
            block.timestamp;

        if (_choice) {
            _singleBetDetails[_betID].accepted = true;
            _validators[msg.sender].betsAccepted += 1;
            emit Bet_Accepted(_betID, _choice, msg.sender);
        } else {
            _singleBetDetails[_betID].accepted = false;
            _validators[msg.sender].betsRejected += 1;
            emit Bet_Denied(_betID, _choice, msg.sender);
        }
    }

    function validateBet(uint256 _betID, uint256 _outcome) public {
        require(_singleBetDetails[_betID].betType, "#04");
        require(_singleBetDetails[_betID].accepted, "#02");
        require(_singleBetDetails[_betID].outcome == 0, "#19");

        bool isValidator;
        for (
            uint index = 0;
            index < _singleBetDetails[_betID].validators.length;
            index++
        ) {
            address currentValidator = _singleBetDetails[_betID].validators[
                index
            ];
            if (currentValidator == msg.sender) {
                isValidator = true;
                break;
            }
        }
        require(isValidator, "#17");

        require(!_hasValidated[msg.sender][_betID], "#35");

        require(_outcome == 1 || _outcome == 2, "#18");

        _singleBetDetails[_betID].validationCount += 1;
        _hasValidated[msg.sender][_betID] = true;

        if (_singleBetDetails[_betID].betType) {
            _singleBetDetails[_betID].outcome = _outcome;
            _validators[msg.sender].betsValidated += 1;
        } else {
            if (_outcome == 1) {
                _singleBetDetails[_betID].betStatistics.yesOutcomeCount += 1;
            }

            if (_outcome == 2) {
                _singleBetDetails[_betID].betStatistics.noOutcomeCount += 1;
            }

            if (_singleBetDetails[_betID].validationCount == 3) {
                if (
                    _singleBetDetails[_betID].betStatistics.yesOutcomeCount >
                    _singleBetDetails[_betID].betStatistics.noOutcomeCount
                ) {
                    _singleBetDetails[_betID].outcome = 1;
                } else {
                    _singleBetDetails[_betID].outcome = 2;
                }
            }
        }

        uint256 validatorReward;
        if (_outcome == 1) {
            validatorReward =
                ((_singleBetDetails[_betID].betStatistics.noPool * 10) / 100) /
                _singleBetDetails[_betID].validators.length;
        }
        if (_outcome == 2) {
            validatorReward =
                ((_singleBetDetails[_betID].betStatistics.yesPool * 10) / 100) /
                _singleBetDetails[_betID].validators.length;
        }

        _validators[msg.sender].balance += validatorReward;

        _singleBetDetails[_betID].claimWaitTime =
            block.timestamp +
            CLAIM_WINNING_WAIT_TIME;

        emit Bet_Validated(_betID, _outcome, msg.sender);
    }

    function reportValidator(
        uint256 _betID,
        string memory _description
    ) public {
        address validator = _singleBetDetails[_betID].validators[0];

        require(_betID <= singleBetIDCounter, "#01");
        require(_singleBetDetails[_betID].betType, "#04");
        require(_singleBetDetails[_betID].betReport.reportOutcome == 0, "#20");
        require(
            !_singleBetDetails[_betID].betReport.currentlyChallenged,
            "#22"
        );
        require(
            block.timestamp < _singleBetDetails[_betID].claimWaitTime,
            "#24"
        );

        _singleBetDetails[_betID].betReport.reporter = msg.sender;
        _singleBetDetails[_betID].betReport.maliciousValidator = validator;
        _singleBetDetails[_betID].betReport.betId = _betID;
        _singleBetDetails[_betID].betReport.currentlyChallenged = true;
        _singleBetDetails[_betID].betReport.description = _description;

        _singleBetDetails[_betID].betReport.voteTime =
            block.timestamp +
            VALIDATOR_VOTE_TIME;

        emit Validator_Reported(
            msg.sender,
            validator,
            _description,
            _betID,
            block.timestamp + VALIDATOR_VOTE_TIME
        );
    }

    function voteValidator(uint256 _betID, bool _choice) public {
        require(_betID <= singleBetIDCounter, "#01");
        require(_singleBetDetails[_betID].betReport.currentlyChallenged, "#25");
        require(!_hasVoted[msg.sender][_betID], "#26");
        require(_isValidator[msg.sender], "#16");
        require(
            block.timestamp < _singleBetDetails[_betID].betReport.voteTime,
            "#26"
        );

        _hasVoted[msg.sender][_betID] = true;
        uint256 requiredValidators = ((validators.length * 50) / 100);

        if (_choice) {
            _singleBetDetails[_betID].betReport.support += 1;
            uint256 support = _singleBetDetails[_betID].betReport.support;
            //
            if (support > requiredValidators) {
                _singleBetDetails[_betID].betReport.reportOutcome = 1;
                _singleBetDetails[_betID].betReport.currentlyChallenged = false;
            }
        } else {
            _singleBetDetails[_betID].betReport.oppose += 1;
            uint256 oppose = _singleBetDetails[_betID].betReport.oppose;
            //
            if (oppose > requiredValidators) {
                _singleBetDetails[_betID].betReport.reportOutcome = 2;
                _singleBetDetails[_betID].betReport.currentlyChallenged = false;

                // SLASH VALIDATOR
                uint256 maliciousValidatorBalance = _validators[
                    _singleBetDetails[_betID].betReport.maliciousValidator
                ].balance;

                _validators[_singleBetDetails[_betID].betReport.reporter]
                    .balance += maliciousValidatorBalance;

                _validators[
                    _singleBetDetails[_betID].betReport.maliciousValidator
                ].balance = 0;

                // REMOVE FROM BEING ABLE TO VALIDATE
                _canValidate[
                    _singleBetDetails[_betID].betReport.maliciousValidator
                ] = false;
            }
        }
    }

    function fundAccount(uint256 _amount) public {
        IERC20(oddsTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        _userDetails[msg.sender].balance += _amount;
    }

    function withdrawFromAccount(uint256 _amount) public {
        require(_amount <= _userDetails[msg.sender].balance, "#32");
        IERC20(oddsTokenAddress).transfer(msg.sender, _amount);

        _userDetails[msg.sender].balance -= _amount;
    }

    function updateDestinationAddress(
        string memory _destinationAddress
    ) public {
        require(msg.sender == deployer, "!deployer");
        destinationAddress = _destinationAddress;
    }

    // INTERNAL FUNCTIONS

    function _getVRFForValidatorAssignment(
        bool _betType,
        uint256 _betID,
        uint256 _estimatedCrossChainGasAmount
    ) internal {
        uint256 validValidatorsLength;
        for (uint index = 0; index < validators.length; index++) {
            if (_canValidate[validators[index]]) {
                validValidatorsLength += 1;
            }
        }

        bytes memory payload = abi.encode(
            _betType,
            _betID,
            validValidatorsLength
        );

        gasService.payNativeGasForContractCall{
            value: _estimatedCrossChainGasAmount
        }(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            address(this)
        );

        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    // CROSS CHAIN VRF CALL
    function _execute(
        string calldata,
        string calldata,
        bytes calldata payload
    ) internal override {
        //decode params
        (uint256 randomNumber, bool betType, uint256 betID) = abi.decode(
            payload,
            (uint256, bool, uint256)
        );

        uint256 validValidatorsLength;

        for (uint index = 0; index < validators.length; index++) {
            if (_canValidate[validators[index]]) {
                validValidatorsLength += 1;
            }
        }

        address[] memory validValidators = new address[](validValidatorsLength);
        uint256 indexCounter;
        for (uint index = 0; index < validators.length; index++) {
            if (_canValidate[validators[index]]) {
                validValidators[indexCounter] = validators[index];
                indexCounter++;
            }
        }

        // assign validator to bet
        _singleBetDetails[betID].validators = [validValidators[randomNumber]];

        emit Validator_Assigned(betID, betType, randomNumber);
    }

    // GETTER FUNCTIONS

    function getUserStakeAmount(
        address _user,
        uint256 _betID
    ) public view returns (uint256) {
        return _userBetAmount[msg.sender][_betID];
    }

    function getUserWinnings(
        uint256 _betID,
        address _user
    ) public view returns (uint256 userWinnings) {
        bool winner = getIsWinner(_betID, _user);

        require(winner, "#33");
        uint256 outCome = _singleBetDetails[_betID].outcome;
        uint256 amount = _userBetAmount[msg.sender][_betID];

        uint256 supportPoolBalance;
        uint256 opposingPoolBalance;

        if (outCome == 1) {
            supportPoolBalance = _singleBetDetails[_betID]
                .betStatistics
                .yesPool;

            opposingPoolBalance = _singleBetDetails[_betID]
                .betStatistics
                .noPool;

            uint256 usersShareInRewardPool = (amount * 100) /
                supportPoolBalance;

            userWinnings = (usersShareInRewardPool * opposingPoolBalance) / 100;
        }

        if (outCome == 2) {
            supportPoolBalance = _singleBetDetails[_betID].betStatistics.noPool;

            opposingPoolBalance = _singleBetDetails[_betID]
                .betStatistics
                .yesPool;

            uint256 usersShareInRewardPool = (amount * 100) /
                supportPoolBalance;

            userWinnings = (usersShareInRewardPool * opposingPoolBalance) / 100;
        }
    }

    function getIsWinner(
        uint256 _betID,
        address _user
    ) public view returns (bool isWinner) {
        uint256 outCome = _singleBetDetails[_betID].outcome;
        uint256 userChoice = _userBetChoice[_user][_betID];

        if (userChoice == outCome) {
            isWinner = true;
        } else {
            isWinner = false;
        }
    }

    function getUserPossibleRewards(
        uint256 _amount,
        uint256 _betID,
        address _user,
        uint256 _choice
    ) public view returns (uint256 usersShareInRewardPool) {
        //  uint256 _choice // 1 - yes || 2 - no

        uint256 supportPoolBalance;
        uint256 opposingPoolBalance;

        if (_choice == 1) {
            supportPoolBalance =
                _singleBetDetails[_betID].betStatistics.yesPool +
                _amount;

            opposingPoolBalance = _singleBetDetails[_betID]
                .betStatistics
                .noPool;

            uint256 usersShareInSupportingPool = (_amount * 100) /
                supportPoolBalance;

            usersShareInRewardPool =
                (usersShareInRewardPool * opposingPoolBalance) /
                100;
        }

        if (_choice == 2) {
            supportPoolBalance =
                _singleBetDetails[_betID].betStatistics.noPool +
                _amount;

            opposingPoolBalance = _singleBetDetails[_betID]
                .betStatistics
                .yesPool;

            uint256 usersShareInSupportingPool = (_amount * 100) /
                supportPoolBalance;

            usersShareInRewardPool =
                (usersShareInRewardPool * opposingPoolBalance) /
                100;
        }
    }

    function getIsValidator(address _user) public view returns (bool) {
        return _isValidator[_user];
    }

    function getUserOddsBalance(address _user) public view returns (uint256) {
        return IERC20(oddsTokenAddress).balanceOf(_user);
    }

    function getCurrentTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getUserDetails() public view returns (User memory) {
        return _userDetails[msg.sender];
    }

    // TEST FUNCTIONS
    function withdrawAllFunds() public {
        uint256 contractBalance = address(this).balance;
        require(msg.sender == deployer, "! deployer");
        (bool success, ) = msg.sender.call{value: contractBalance}("");
        require(success, "! successful");
    }

    receive() external payable {}
}
