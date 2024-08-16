// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IConditionModule} from "../interfaces/IConditionModule.sol";

contract MockConditionModule is IConditionModule {
    string public name = "MockConditionModule";

    function initialize(
        uint256,
        bytes calldata
    ) external pure override returns (bool) {
        return true;
    }

    function enroll(
        uint256,
        address,
        address,
        bytes calldata
    ) external payable override returns (bool) {
        return true;
    }

    function cancel(
        uint256,
        address,
        address[] calldata,
        bytes calldata
    ) external pure override returns (bool) {
        return true;
    }

    function checkAttendees(
        uint256,
        address[] calldata,
        bytes calldata
    ) external pure override returns (bool) {
        return true;
    }

    function settle(
        uint256,
        address[] calldata,
        bytes calldata
    ) external pure override returns (bool) {
        return true;
    }
}
