// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@axelar/contracts/executable/AxelarExecutable.sol";
import "@axelar/contracts/interfaces/IAxelarGasService.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract OddsVRFHelper is AxelarExecutable, VRFConsumerBaseV2 {
    string public destinationChain = "Moonbeam";
    string public destinationAddress;

    bytes32 public keyHash;
    uint64 public subscriptionId;
    uint32 public callBackGasLimit;
    uint32 public numWords;
    uint16 public requestconfirmations;

    uint256 public estimatedCrossChainGasAmount;

    address public deployer;

    IAxelarGasService public immutable gasService;
    VRFCoordinatorV2Interface public COORDINATOR;

    struct RequestDetails {
        uint256 requestId;
        uint256 betID;
        uint256 validatorCount;
        bool betType;
        bool exists;
        bool fulfilled;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestDetails) public _requestDetails;

    constructor(
        address _gateway,
        address _gasReceiver,
        address _vrfCoordinator,
        string memory _destinationAddress,
        uint64 _subscriptionId
    ) AxelarExecutable(_gateway) VRFConsumerBaseV2(_vrfCoordinator) {
        gasService = IAxelarGasService(_gasReceiver);
        destinationAddress = _destinationAddress;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);

        subscriptionId = _subscriptionId;

        deployer = msg.sender;
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestconfirmations,
            callBackGasLimit,
            numWords
        );
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(_requestDetails[_requestId].exists, "request not found");

        _requestDetails[_requestId].fulfilled = true;
        _requestDetails[_requestId].randomWords = _randomWords;

        uint256 _validatorCount = _requestDetails[_requestId].validatorCount;
        uint256 betID = _requestDetails[_requestId].betID;
        bool betType = _requestDetails[_requestId].betType;

        uint256 randomNumber = (_randomWords[0] % _validatorCount);

        _feedOddsWithRandomNumber(randomNumber, betID, betType);
    }

    function _feedOddsWithRandomNumber(
        uint256 _randomNumber,
        uint256 _betID,
        bool _betType
    ) internal {
        bytes memory payload = abi.encode(_randomNumber, _betType, _betID);

        gasService.payNativeGasForContractCall{
            value: estimatedCrossChainGasAmount
        }(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            address(this)
        );

        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        // decode payload
        (bool _betType, uint256 _betID, uint256 _validatorCount) = abi.decode(
            payload,
            (bool, uint256, uint256)
        );

        uint256 requestId = requestRandomWords();
        _requestDetails[requestId].betID = _betID;
        _requestDetails[requestId].betType = _betType;
        _requestDetails[requestId].exists = true;
        _requestDetails[requestId].validatorCount = _validatorCount;
        _requestDetails[requestId].requestId = requestId;
    }

    function updateDestinationAddress(
        string memory _destinationAddress
    ) public {
        require(msg.sender == deployer, "!deployer");
        destinationAddress = _destinationAddress;
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
