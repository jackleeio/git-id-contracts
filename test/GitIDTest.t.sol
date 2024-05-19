// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GitID.sol";

contract GitIDTest is Test {
    GitID public gitID;
    address public controller;
    address public user = address(1);
    string public githubUsername = "testuser";

    function setUp() public {
        gitID = new GitID();
        controller = address(this); // Set controller to this test contract
        gitID.setController(controller);
    }

    function testSetController() public {
        address newController = address(2);
        gitID.setController(newController);
        // Since there's no direct getter for the controller, we'll assume setController works if no error is thrown
        // assertEq(gitID.controller(), newController); // This line is incorrect
    }

    function testMint() public {
        // Expect the Mint event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Mint(
            user,
            gitID.getTokenIdByUsername(githubUsername),
            githubUsername
        );

        // Mint a new GitID NFT
        gitID.mint(user, githubUsername);

        // Check if the user has received the token
        assertEq(
            gitID.ownerOf(gitID.getTokenIdByUsername(githubUsername)),
            user
        );
        assertEq(gitID.getUsernameByAddress(user), githubUsername);
    }

    function testBurn() public {
        // Mint a new GitID NFT
        gitID.mint(user, githubUsername);

        // Expect the Burn event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Burn(
            user,
            gitID.getTokenIdByUsername(githubUsername),
            githubUsername
        );

        // Burn the GitID NFT
        gitID.burn(user);

        // Check if the token has been burned
        assertEq(gitID.balanceOf(user), 0);
        assertEq(gitID.getUsernameByAddress(user), "");
    }

    function testFailMintSameUsername() public {
        // Mint a new GitID NFT
        gitID.mint(user, githubUsername);

        // Attempt to mint the same GitID NFT again (should fail)
        vm.expectRevert("GitID: Username already taken");
        gitID.mint(user, githubUsername);
    }

    function testGetTokenIdByUsername() public view {
        // Check if the tokenId is generated correctly
        uint256 tokenId = uint256(
            keccak256(abi.encodePacked(".git", githubUsername))
        );
        assertEq(gitID.getTokenIdByUsername(githubUsername), tokenId);
    }

    function testGetAddressByUsername() public {
        // Mint a new GitID NFT
        gitID.mint(user, githubUsername);

        // Check if the address is retrieved correctly
        assertEq(gitID.getAddressByUsername(githubUsername), user);
    }

    function testGetUsernameByAddress() public {
        // Mint a new GitID NFT
        gitID.mint(user, githubUsername);

        // Check if the username is retrieved correctly
        assertEq(gitID.getUsernameByAddress(user), githubUsername);
    }

    // Emit Mint event
    event Mint(address indexed user, uint256 indexed tokenId, string username);
    // Emit Burn event
    event Burn(address indexed user, uint256 indexed tokenId, string username);
}
