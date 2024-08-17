// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Common.sol";

interface IConditionModule {
    /* Getters */
    function name() external view returns (string memory);

    /* Setters */
    function initialize(
        uint256 id,
        bytes calldata data
    ) external returns (bool);

    function enroll(
        uint256 id,
        address enrollee,
        address sender
    ) external payable returns (bool);

    function cancel(
        uint256 id,
        address owner,
        address[] calldata registrations
    ) external returns (bool);

    function checkAttendees(
        uint256 id,
        address[] calldata attendees
    ) external returns (bool);

    function settle(
        uint256 id,
        address[] calldata attendees
    ) external returns (bool);
}
