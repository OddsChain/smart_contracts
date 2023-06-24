// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OddsToken is ERC20 {
    constructor() ERC20("Odds Token ", "ODDS") {}

    function mintFree(address _user, uint256 _amount) public {
        _mint(_user, _amount);
    }
}
