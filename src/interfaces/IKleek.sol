// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../Common.sol";

interface IKleek {
    /* Kleek events */
    event ConditionModuleWhitelisted(
        address indexed module,
        string name,
        bool whitelisted,
        address sender,
        uint256 timestamp
    );

    /* Registry events */
    event EventCreated(
        uint256 indexed eventId,
        address indexed owner,
        string contentUri,
        uint256 endDate,
        uint256 timestamp
    );
    event EventUpdated(
        uint256 indexed eventId,
        address indexed owner,
        string contentUri,
        uint256 timestamp
    );
    event EventCanceled(
        uint256 indexed eventId,
        string reason,
        bytes data,
        address sender,
        uint256 timestamp
    );
    event NewEnrollee(
        uint256 indexed eventId,
        address indexed enrollee,
        address sender,
        uint256 timestamp
    );
    event AttendeesChecked(
        uint256 indexed eventId,
        address[] attendees,
        bytes data,
        address sender,
        uint256 timestamp
    );
    event EventSettled(
        uint256 indexed eventId,
        bytes data,
        address sender,
        uint256 timestamp
    );

    /* Getters */
    function getEventRecord(
        uint256 id
    )
        external
        view
        returns (
            address owner,
            uint256 endDate,
            uint256 registerBefore,
            uint256 capacity,
            string memory contentUri,
            address conditionModule,
            Status status
        );

    /* Klee functions */
    function whitelistConditionModule(address module, bool enable) external;

    /* Registry functions */
    function create(
        string calldata _contentUri,
        uint256 _endDate,
        uint256 _registerBefore,
        uint256 _capacity,
        address _conditionModule,
        bytes calldata _conditionModuleData
    ) external;

    function updateContentUri(
        uint256 eventId,
        string calldata contentUri
    ) external;

    // function cancel(
    //     uint256 eventId,
    //     string calldata reason,
    //     bytes calldata conditionModuleData
    // ) external;

    //     function enroll(
    //         uint256 eventId,
    //         address enrollee,
    //         bytes calldata conditionModuleData
    //     ) external payable;

    //     function checkAttendees(
    //         uint256 eventId,
    //         address[] calldata attendees,
    //         bytes calldata conditionModuleData
    //     ) external;

    //     function settle(
    //         uint256 eventId,
    //         bytes calldata conditionModuleData
    //     ) external;
}
