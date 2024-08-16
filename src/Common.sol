// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

error AccessDenied();
error AlreadyEnrolled();
error AlreadyStarted();
error InactiveRecord();
error IncorrectValue();
error InvalidAddress();
error InvalidDate();
error InvalidCapacity();
error CapacityReached();
error NoAttendees();
error ModuleNotFound();
error ModuleNotWhitelisted();
error UnexpectedModuleError();

enum Status {
    Active,
    Cancelled,
    Settled
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
    address[] attendees;
    mapping(address => Enrollees) enrollees;
}

struct Enrollees {
    bool enrolled;
    bool attended;
}
