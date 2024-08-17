// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Upgrades, UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Test, console} from "forge-std/Test.sol";

import {Kleek} from "../src/Kleek.sol";
import {IConditionModule} from "../src/interfaces/IConditionModule.sol";
import {MockConditionModule} from "../src/mocks/MockConditionModule.sol";
import "../src/interfaces/IKleek.sol";
import "../src/Common.sol";

contract KleekTest is Test {
    Kleek public kleekImplementation;
    Kleek public kleek;
    MockConditionModule public mockModule;
    address public owner;
    address public user;

    event ConditionModuleWhitelisted(
        address indexed module,
        string name,
        bool whitelisted,
        address sender,
        uint256 timestamp
    );

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

    event NewEnrollee(
        uint256 indexed eventId,
        address indexed enrollee,
        address sender,
        uint256 timestamp
    );

    function setUp() public {
        owner = address(this);
        user = address(0x1);

        kleekImplementation = new Kleek();
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            address(kleekImplementation),
            abi.encodeCall(Kleek.initialize, ())
        );

        // Cast the proxy address to the Kleek interface
        kleek = Kleek(address(proxy));

        mockModule = new MockConditionModule(address(kleek));
    }

    function testInitialize() public {
        // Test that the contract is properly initialized
        assertEq(kleek.owner(), owner);
        assertEq(kleek.eventCount(), 0);

        // Test that we can't initialize again
        vm.expectRevert();
        kleek.initialize();
    }

    function testWhitelistConditionModule() public {
        // Test whitelisting a module
        vm.expectEmit(true, false, false, true);
        emit ConditionModuleWhitelisted(
            address(mockModule),
            "MockConditionModule",
            true,
            owner,
            block.timestamp
        );
        kleek.whitelistConditionModule(address(mockModule), true);

        // Create an event to verify the module is whitelisted
        uint256 endDate = block.timestamp + 1 days;
        uint256 registerBefore = block.timestamp + 12 hours;
        kleek.create(
            "ipfs://content",
            endDate,
            registerBefore,
            100,
            address(mockModule),
            ""
        );

        // Test un-whitelisting a module
        vm.expectEmit(true, false, false, true);
        emit ConditionModuleWhitelisted(
            address(mockModule),
            "MockConditionModule",
            false,
            owner,
            block.timestamp
        );
        kleek.whitelistConditionModule(address(mockModule), false);

        // Attempt to create an event with un-whitelisted module (should revert)
        vm.expectRevert(ModuleNotWhitelisted.selector);
        kleek.create(
            "ipfs://content2",
            endDate,
            registerBefore,
            100,
            address(mockModule),
            ""
        );
    }

    function testCreate() public {
        kleek.whitelistConditionModule(address(mockModule), true);

        uint256 endDate = block.timestamp + 1 days;
        uint256 registerBefore = block.timestamp + 12 hours;

        uint256 eventId = kleek.eventCount();

        vm.expectEmit(true, true, false, true);
        emit EventCreated(
            eventId,
            owner,
            "ipfs://content",
            endDate,
            block.timestamp
        );
        kleek.create(
            "ipfs://content",
            endDate,
            registerBefore,
            100,
            address(mockModule),
            ""
        );

        // Verify event details
        (
            address recordOwner,
            uint256 recordEndDate,
            uint256 recordRegisterBefore,
            uint256 recordCapacity,
            string memory recordContentUri,
            address recordConditionModule,
            uint256 totalEnrollees,
            Status recordStatus
        ) = kleek.getEventRecord(eventId);

        assertEq(recordOwner, owner);
        assertEq(recordContentUri, "ipfs://content");
        assertEq(recordEndDate, endDate);
        assertEq(recordRegisterBefore, registerBefore);
        assertEq(recordCapacity, 100);
        assertEq(recordConditionModule, address(mockModule));
        assertEq(totalEnrollees, 0);
        assertEq(uint(recordStatus), uint(Status.Active));
    }

    function testUpdateContentUri() public {
        kleek.whitelistConditionModule(address(mockModule), true);

        uint256 endDate = block.timestamp + 1 days;
        uint256 registerBefore = block.timestamp + 12 hours;

        uint256 eventId = kleek.eventCount();
        kleek.create(
            "ipfs://content",
            endDate,
            registerBefore,
            100,
            address(mockModule),
            ""
        );

        // Update content URI
        vm.expectEmit(true, true, false, true);
        emit EventUpdated(
            eventId,
            owner,
            "ipfs://new-content",
            block.timestamp
        );
        kleek.updateContentUri(eventId, "ipfs://new-content");

        // Verify updated content URI
        (, , , , string memory updatedContentUri, , , ) = kleek.getEventRecord(
            eventId
        );
        assertEq(updatedContentUri, "ipfs://new-content");

        // Test updating non-existent event
        vm.expectRevert(EventNotFound.selector);
        kleek.updateContentUri(999, "ipfs://non-existent");

        // Test updating by non-owner
        vm.prank(user);
        vm.expectRevert(AccessDenied.selector);
        kleek.updateContentUri(eventId, "ipfs://unauthorized");

        // Test updating after event has ended
        vm.warp(registerBefore + 1);
        vm.expectRevert(RegistrationClosed.selector);
        kleek.updateContentUri(eventId, "ipfs://too-late");
    }

    function testEnroll() public {
        kleek.whitelistConditionModule(address(mockModule), true);

        uint256 endDate = block.timestamp + 1 days;
        uint256 registerBefore = block.timestamp + 12 hours;

        uint256 eventId = kleek.eventCount();
        kleek.create(
            "ipfs://content",
            endDate,
            registerBefore,
            100,
            address(mockModule),
            ""
        );

        vm.expectEmit(true, true, false, true);
        emit NewEnrollee(eventId, user, owner, block.timestamp);
        kleek.enroll(eventId, user);

        // Test enrolling twice
        vm.expectRevert(AlreadyEnrolled.selector);
        kleek.enroll(eventId, user);

        // Test enrolling in non-existent event
        vm.expectRevert(EventNotFound.selector);
        kleek.enroll(999, user);

        // Test enrolling when event is full
        uint256 smallEventId = kleek.eventCount();
        kleek.create(
            "ipfs://small-event",
            endDate,
            registerBefore,
            1,
            address(mockModule),
            ""
        );
        kleek.enroll(smallEventId, user);
        vm.expectRevert(CapacityReached.selector);
        kleek.enroll(smallEventId, address(0x2));

        // Test enrolling after registration is closed
        vm.warp(registerBefore + 1);
        vm.expectRevert(RegistrationClosed.selector);
        kleek.enroll(eventId, address(0x2));
    }
}
