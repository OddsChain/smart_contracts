// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library DataTypes {
    struct CreateSingleBetParams {
        string description;
        bool betType;
        uint256 betEndTime;
        address[] validators;
    }

    struct CreateMultiBetParams {
        uint256[] betIDs;
        uint256[] choices;
        string description;
        uint256 amount;
    }
}
