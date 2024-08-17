// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockConditionModule is Ownable {
    constructor(address owner) Ownable(owner) {}

    function initialize(
        uint256 id,
        bytes calldata data
    ) external virtual onlyOwner returns (bool) {
        return true;
    }

    function cancel(
        uint256 id,
        address owner,
        address[] calldata registrations
    ) external virtual onlyOwner returns (bool) {
        return true;
    }

    function enroll(
        uint256 id,
        address participant,
        address sender
    ) external payable virtual onlyOwner returns (bool) {
        return true;
    }

    function checkAttendees(
        uint256 id,
        address[] calldata attendees
    ) external virtual onlyOwner returns (bool) {
        return true;
    }

    function settle(
        uint256 id,
        address[] calldata attendees
    ) external virtual onlyOwner returns (bool) {
        return true;
    }

    function name() external pure returns (string memory) {
        return "MockConditionModule";
    }
}
