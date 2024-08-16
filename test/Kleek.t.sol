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

    function setUp() public {
        owner = address(this);
        user = address(0x1);

        address kleekImplementation = address(new Kleek());
        address proxy = UnsafeUpgrades.deployUUPSProxy(
            kleekImplementation,
            abi.encodeCall(Kleek.initialize, (owner))
        );

        // Cast the proxy address to the Kleek interface
        kleek = Kleek(address(proxy));

        mockModule = new MockConditionModule();
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
            Status recordStatus
        ) = kleek.getEventRecord(eventId);

        assertEq(recordOwner, owner);
        assertEq(recordContentUri, "ipfs://content");
        assertEq(recordEndDate, endDate);
        assertEq(recordRegisterBefore, registerBefore);
        assertEq(recordCapacity, 100);
        assertEq(recordConditionModule, address(mockModule));
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
        (, , , , string memory updatedContentUri, , ) = kleek.getEventRecord(
            eventId
        );
        assertEq(updatedContentUri, "ipfs://new-content");

        // Test updating content URI for non-existent event (should revert)
        vm.expectRevert("InvalidEventId");
        kleek.updateContentUri(999, "ipfs://non-existent");

        // Test updating content URI for an event that has ended (should revert)
        vm.warp(endDate + 1);
        vm.expectRevert("InvalidDate");
        kleek.updateContentUri(eventId, "ipfs://too-late");

        // Test updating content URI by non-owner (should revert)
        vm.prank(user);
        vm.expectRevert("AccessDenied");
        kleek.updateContentUri(eventId, "ipfs://unauthorized");
    }
}
