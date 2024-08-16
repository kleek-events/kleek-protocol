// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IKleek} from "./interfaces/IKleek.sol";
import {IConditionModule} from "./interfaces/IConditionModule.sol";
import "./Common.sol";

contract Kleek is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IKleek
{
    mapping(uint256 => EventRecord) internal eventRecords;
    mapping(address => bool) internal conditionModules;
    uint256 public eventCount = 0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
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
    ) external {
        verifyConditionModule(_conditionModule);
        verifyEndDate(_endDate);
        verifyRegisterBefore(_registerBefore, _endDate);
        verifyCapacity(_capacity);

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

        eventCount++;
    }

    function updateContentUri(uint256 id, string calldata contentUri) external {
        require(id < eventCount, "InvalidEventId");

        EventRecord storage eventRecord = eventRecords[id];
        require(eventRecord.status == Status.Active, "InactiveEvent");
        require(eventRecord.owner == msg.sender, "AccessDenied");
        require(eventRecord.endDate > block.timestamp, "InvalidDate");

        eventRecord.contentUri = contentUri;

        emit EventUpdated(id, msg.sender, contentUri, block.timestamp);
    }

    // function enroll(uint256 _id, address _attendee) external {
    //     EventRecord storage eventRecord = eventRecords[_id];
    //     require(eventRecord.status == Status.Active, "InactiveEvent");
    //     require(eventRecord.endDate > block.timestamp, "InvalidDate");
    //     require(eventRecord.registerBefore > block.timestamp, "DealineReached");
    //     require(eventRecord.capacity > 0, "LimitReached");
    //     require(
    //         eventRecord.attendees.length < eventRecord.capacity,
    //         "CapacityReached"
    //     );
    //     require(
    //         !eventRecord.registrations[msg.sender].registered,
    //         "AlreadyRegistered"
    //     );

    //     eventRecord.attendees.push(msg.sender);
    //     eventRecord.registrations[msg.sender].registered = true;

    //     emit NewEnrollee(_id, _attendee, msg.sender, block.timestamp);
    // }

    // function checkAttendees(
    //     uint256 eventId,
    //     address[] calldata attendees,
    //     bytes calldata conditionModuleData
    // ) external {}

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

    /* Require function */
    function verifyConditionModule(address _conditionModule) internal view {
        if (_conditionModule == address(0)) revert ModuleNotFound();
        if (!conditionModules[_conditionModule]) revert ModuleNotWhitelisted();
    }

    function verifyEndDate(uint256 _endDate) internal view {
        if (_endDate < block.timestamp) revert InvalidDate();
    }

    function verifyRegisterBefore(
        uint256 _registerBefore,
        uint256 _endDate
    ) internal view {
        if (_registerBefore < block.timestamp || _registerBefore > _endDate)
            revert InvalidDate();
    }

    function verifyCapacity(uint256 _capacity) internal pure {
        if (_capacity < 0) revert InvalidCapacity();
    }

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
        )
    {
        return (
            eventRecords[id].owner,
            eventRecords[id].endDate,
            eventRecords[id].registerBefore,
            eventRecords[id].capacity,
            eventRecords[id].contentUri,
            eventRecords[id].conditionModule,
            eventRecords[id].status
        );
    }

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
