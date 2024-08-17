// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../Common.sol";

contract TransferDeposit is Ownable {
    struct Conditions {
        uint256 depositFee;
        address tokenAddress;
        address recipient;
    }

    mapping(uint256 => Conditions) internal conditions;
    mapping(uint256 => uint256) internal totalDeposits;
    mapping(uint256 => uint256) internal totalFunded;

    string public name;

    constructor(address owner) Ownable(owner) {
        name = "TransferDeposit";
    }

    function initialize(
        uint256 id,
        bytes calldata data
    ) external virtual onlyOwner returns (bool) {
        Conditions memory _conditions = abi.decode(data, (Conditions));

        conditions[id] = _conditions;

        return true;
    }

    function enroll(
        uint256 id,
        address enrollee,
        address sender
    ) external payable virtual onlyOwner returns (bool) {
        if (msg.value > 0) revert IncorrectValue();

        IERC20 token = IERC20(conditions[id].tokenAddress);
        require(
            token.transferFrom(sender, address(this), conditions[id].depositFee)
        );

        totalDeposits[id] += conditions[id].depositFee;

        return true;
    }

    function cancel(
        uint256 id,
        address owner,
        address[] calldata registrations
    ) external virtual onlyOwner returns (bool) {
        IERC20 token = IERC20(conditions[id].tokenAddress);

        for (uint256 i = 0; i < registrations.length; i++) {
            require(
                token.transfer(registrations[i], conditions[id].depositFee)
            );
        }
        totalDeposits[id] = 0;

        if (totalFunded[id] > 0) {
            require(token.transfer(owner, totalFunded[id]));
            totalFunded[id] = 0;
        }

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
        (bool success, uint256 fundFee) = Math.tryDiv(
            totalFunded[id],
            attendees.length
        );
        if (!success) revert IncorrectValue();

        uint256 totalPayouts = 0;
        uint256 settlementFee = conditions[id].depositFee + fundFee;
        IERC20 token = IERC20(conditions[id].tokenAddress);
        for (uint256 i = 0; i < attendees.length; i++) {
            require(token.transfer(attendees[i], settlementFee));
            totalPayouts += conditions[id].depositFee;
        }

        if (totalDeposits[id] > totalPayouts) {
            uint256 recipientFee = totalDeposits[id] - totalPayouts;
            require(token.transfer(conditions[id].recipient, recipientFee));
        }

        totalDeposits[id] = 0;
        totalFunded[id] = 0;

        return true;
    }

    /* Getters */
    function getConditions(
        uint256 id
    ) external view returns (Conditions memory) {
        return conditions[id];
    }

    function getTotalDeposits(uint256 id) external view returns (uint256) {
        return totalDeposits[id];
    }

    function getTotalFunded(uint256 id) external view returns (uint256) {
        return totalFunded[id];
    }
}
