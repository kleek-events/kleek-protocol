// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

error AccessDenied();
error AlreadyEnrolled();
error AlreadyStarted();
error CapacityReached();
error EventNotFound();
error InactiveEvent();
error IncorrectValue();
error InvalidAddress();
error InvalidDate();
error InvalidCapacity();
error ModuleNotFound();
error ModuleNotWhitelisted();
error NoAttendees();
error UnexpectedModuleError();
error RegistrationClosed();

enum Status {
    Active,
    Cancelled,
    Settled
}

struct People {
    bool enrolled;
    bool attended;
}

struct EventRecord {
    uint256 id;
    Status status;
    address owner;
    string contentUri;
    uint256 endDate;
    uint256 registerBefore;
    uint256 capacity;
    address conditionModule;
    uint256 totalEnrollees;
    mapping(uint256 => address) peopleIndex;
    mapping(address => People) people;
}
