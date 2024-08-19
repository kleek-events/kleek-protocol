// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IKleekCore} from "./interfaces/IKleekCore.sol";
import {IConditionModule} from "./interfaces/IConditionModule.sol";
import "./Common.sol";

contract KleekCore is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IKleekCore
{
    mapping(uint256 => EventRecord) internal eventRecords;
    mapping(address => bool) internal conditionModules;
    uint256 public eventCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        eventCount = 0;
    }

    function whitelistConditionModule(
        address _conditionModule,
        bool _enable
    ) external onlyOwner {
        conditionModules[_conditionModule] = _enable;

        string memory name = IConditionModule(_conditionModule).name();

        emit ConditionModuleWhitelisted(
            _conditionModule,
            name,
            _enable,
            msg.sender,
            block.timestamp
        );
    }

    function create(
        string calldata _contentUri,
        uint256 _endDate,
        uint256 _registerBefore,
        uint256 _capacity,
        address _conditionModule,
        bytes calldata _conditionModuleData
    ) external returns (uint256) {
        isValidConditionModule(_conditionModule);
        isValidEndDate(_endDate);
        isValidRegisterBefore(_registerBefore, _endDate);
        isValidCapacity(_capacity);

        bool result = IConditionModule(_conditionModule).initialize(
            eventCount,
            _conditionModuleData
        );
        if (!result) revert UnexpectedModuleError();

        EventRecord storage eventRecord = eventRecords[eventCount];
        eventRecord.id = eventCount;
        eventRecord.status = Status.Active;
        eventRecord.owner = msg.sender;
        eventRecord.contentUri = _contentUri;
        eventRecord.endDate = _endDate;
        eventRecord.registerBefore = _registerBefore;
        eventRecord.capacity = _capacity;
        eventRecord.conditionModule = _conditionModule;

        emit EventCreated(
            eventCount,
            msg.sender,
            _contentUri,
            _endDate,
            block.timestamp
        );

        uint256 newEventId = eventCount;
        eventCount++;

        return newEventId;
    }

    function updateContentUri(
        uint256 _id,
        string calldata _contentUri
    ) external {
        isValidEvent(_id);
        isRegistrationOpen(_id);
        isEventOwner(_id);

        eventRecords[_id].contentUri = _contentUri;

        emit EventUpdated(_id, msg.sender, _contentUri, block.timestamp);
    }

    function enroll(uint _id, address _enrollee) external {
        isValidEvent(_id);
        isRegistrationOpen(_id);
        isEventNotFull(_id);
        isNotEnrolled(_id, _enrollee);
        isNotEventOwner(_id, _enrollee);

        bool result = IConditionModule(eventRecords[_id].conditionModule)
            .enroll(_id, _enrollee, msg.sender);
        if (!result) revert UnexpectedModuleError();

        eventRecords[_id].people[_enrollee].enrolled = true;
        eventRecords[_id].peopleIndex[
            eventRecords[_id].totalEnrollees
        ] = _enrollee;
        eventRecords[_id].totalEnrollees++;

        emit NewEnrollee(_id, _enrollee, msg.sender, block.timestamp);
    }

    // function checkAttendees(
    //     uint256 _id,
    //     address[] calldata _attendees
    // ) external {
    //     isValidEvent(_id);
    //     isEventOwner(_id);

    //     uint attendeesCount = 0;
    //     address[] memory validAttendees = new address[](_attendees.length);
    //     for (uint256 i = 0; i < _attendees.length; i++) {
    //         if (!eventRecords[_id].people[_attendees[i]].enrolled) {
    //             continue;
    //         }
    //         if (eventRecords[_id].people[_attendees[i]].attended) {
    //             continue;
    //         }

    //         eventRecords[_id].people[_attendees[i]].attended = true;
    //         eventRecords[_id].totalEnrollees++;
    //         validAttendees[attendeesCount] = _attendees[i];
    //         attendeesCount++;
    //     }

    //     address[] memory attendees = new address[](attendeesCount);
    //     for (uint256 i = 0; i < attendees.length; i++) {
    //         if (validAttendees[i] == address(0)) {
    //             continue;
    //         }

    //         attendees[i] = validAttendees[i];
    //     }

    //     bool result = IConditionModule(eventRecords[_id].conditionModule)
    //         .checkAttendees(_id, attendees);
    //     if (!result) revert UnexpectedModuleError();

    //     emit AttendeesChecked(_id, attendees, msg.sender, block.timestamp);
    // }

    // function settle(
    //     uint256 eventId,
    //     bytes calldata conditionModuleData
    // ) external {
    //     EventRecord storage eventRecord = eventRecords[eventId];
    //     require(eventRecord.status == Status.Active, "InactiveEvent");
    //     require(eventRecord.endDate < block.timestamp, "InvalidDate");

    //     eventRecord.status = Status.Settled;

    //     emit EventSettled(
    //         eventId,
    //         conditionModuleData,
    //         msg.sender,
    //         block.timestamp
    //     );
    // }

    /* Verifiers */
    function isValidConditionModule(address _conditionModule) internal view {
        if (_conditionModule == address(0)) revert ModuleNotFound();
        if (!conditionModules[_conditionModule]) revert ModuleNotWhitelisted();
    }

    function isValidEndDate(uint256 _endDate) internal view {
        if (_endDate < block.timestamp) revert InvalidDate();
    }

    function isValidRegisterBefore(
        uint256 _registerBefore,
        uint256 _endDate
    ) internal view {
        if (_registerBefore < block.timestamp || _registerBefore > _endDate)
            revert InvalidDate();
    }

    function isValidCapacity(uint256 _capacity) internal pure {
        if (_capacity < 0) revert InvalidCapacity();
    }

    function isValidEvent(uint256 _id) internal view {
        if (eventRecords[_id].owner == address(0)) revert EventNotFound();
        if (eventRecords[_id].status != Status.Active) revert InactiveEvent();
    }

    function isRegistrationOpen(uint256 _id) internal view {
        if (eventRecords[_id].registerBefore < block.timestamp)
            revert RegistrationClosed();
    }

    function isEventNotFull(uint256 _id) internal view {
        if (
            eventRecords[_id].capacity > 0 &&
            eventRecords[_id].capacity == eventRecords[_id].totalEnrollees
        ) revert CapacityReached();
    }

    function isNotEnrolled(uint256 _id, address _enrollee) internal view {
        if (eventRecords[_id].people[_enrollee].enrolled)
            revert AlreadyEnrolled();
    }

    function isEventOwner(uint256 _id) internal view {
        if (eventRecords[_id].owner != msg.sender) revert AccessDenied();
    }

    function isNotEventOwner(uint256 _id, address _enrollee) internal view {
        if (eventRecords[_id].owner == _enrollee) revert AccessDenied();
    }

    /* Getters */
    function getEventRecord(
        uint256 id
    )
        external
        view
        returns (
            address owner,
            string memory contentUri,
            address conditionModule,
            uint256 totalEnrollees,
            Status status
        )
    {
        return (
            eventRecords[id].owner,
            eventRecords[id].contentUri,
            eventRecords[id].conditionModule,
            eventRecords[id].totalEnrollees,
            eventRecords[id].status
        );
    }

    // function getEnrollees(
    //     uint256 _id
    // ) external view returns (address[] memory) {
    //     uint totalEnrollees = 0;
    //     address[] memory enrolless = new address[](
    //         eventRecords[_id].totalEnrollees
    //     );
    //     for (uint256 i = 0; i < eventRecords[_id].totalEnrollees; i++) {
    //         if (
    //             !eventRecords[_id]
    //                 .people[eventRecords[_id].peopleIndex[i]]
    //                 .attended
    //         ) {
    //             continue;
    //         }

    //         enrolless[totalEnrollees] = eventRecords[_id].peopleIndex[i];
    //         totalEnrollees++;
    //     }

    //     return enrolless;
    // }

    /* Pausable */
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /* UUPS */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
