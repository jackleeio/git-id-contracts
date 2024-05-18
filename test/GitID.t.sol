// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GitID.sol";

contract GitIDTest is Test {
    GitID public gitID;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x2);

        // 部署合约并设置所有者
        gitID = new GitID();
        gitID.transferOwnership(owner);
    }

    function testMint() public {
        vm.prank(owner);
        gitID.mint(user, "testuser");
        assertEq(gitID.getUsernameByAddress(user), "testuser");
    }

    function testMintBurnMint() public {
        vm.prank(owner);
        gitID.mint(user, "testuser");
        assertEq(gitID.getUsernameByAddress(user), "testuser");

        // 再次铸造前烧毁旧的 GitID
        vm.prank(owner);
        gitID.burn(user);
        assertEq(gitID.getUsernameByAddress(user), "");

        // 再次铸造新的 GitID
        vm.prank(owner);
        gitID.mint(user, "testuser2");
        assertEq(gitID.getUsernameByAddress(user), "testuser2");
    }

    function testBurn() public {
        vm.prank(owner);
        gitID.mint(user, "testuser3");
        assertEq(gitID.getUsernameByAddress(user), "testuser3");

        vm.prank(owner);
        gitID.burn(user);
        assertEq(gitID.getUsernameByAddress(user), "");
    }

    function testGetAddressByUsername() public {
        vm.prank(owner);
        gitID.mint(user, "testuser");
        assertEq(gitID.getAddressByUsername("testuser"), user);
    }
}
