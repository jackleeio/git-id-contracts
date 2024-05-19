// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GitID.sol";
import "../src/GitIDController.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract GitIDControllerTest is Test {
    GitID public gitID;
    GitIDController public controller;
    address public owner = address(this);
    address public user = address(1);
    address public signer = address(2);
    string public githubUsername = "testuser";
    uint256 public mintFee = 0.069 ether;

    function setUp() public {
        // Deploy GitID contract
        gitID = new GitID();

        // Deploy GitIDController contract
        controller = new GitIDController(address(gitID), signer);

        // Set controller in GitID contract
        gitID.setController(address(controller));
    }

    function testSetSigner() public {
        address newSigner = address(3);
        controller.setSigner(newSigner);
        assertEq(controller.signer(), newSigner);
    }

    function testSetMintFee() public {
        uint256 newFee = 0.1 ether;
        controller.setMintFee(newFee);
        assertEq(controller.mintFee(), newFee);
    }

    function testMintWithValidSignature() public {
        // Prepare message hash
        uint256 chainId = block.chainid;
        uint256 expireAt = block.timestamp + 1 hours;
        uint8 isFree = 0;
        bytes32 messageHash = controller.getMessageHash(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree
        );
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );

        // Sign the message hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Mint a new GitID NFT
        vm.prank(user);
        controller.mint{value: mintFee}(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree,
            signature
        );

        // Check if the user has received the token
        assertEq(
            gitID.ownerOf(gitID.getTokenIdByUsername(githubUsername)),
            user
        );
        assertEq(gitID.getUsernameByAddress(user), githubUsername);
    }

    function testMintWithExpiredSignature() public {
        // Prepare message hash
        uint256 chainId = block.chainid;
        uint256 expireAt = block.timestamp - 1 hours; // Expired time
        uint8 isFree = 0;
        bytes32 messageHash = controller.getMessageHash(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree
        );
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );

        // Sign the message hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Attempt to mint a new GitID NFT with expired signature (should fail)
        vm.prank(user);
        vm.expectRevert("Expired signature");
        controller.mint{value: mintFee}(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree,
            signature
        );
    }

    function testMintWithInvalidSignature() public {
        // Prepare message hash
        uint256 chainId = block.chainid;
        uint256 expireAt = block.timestamp + 1 hours;
        uint8 isFree = 0;
        bytes32 messageHash = controller.getMessageHash(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree
        );
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );

        // Sign the message hash with an incorrect signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            address(3),
            ethSignedMessageHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // Attempt to mint a new GitID NFT with invalid signature (should fail)
        vm.prank(user);
        vm.expectRevert("Invalid signature");
        controller.mint{value: mintFee}(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree,
            signature
        );
    }

    function testMintWithFreeMint() public {
        // Prepare message hash
        uint256 chainId = block.chainid;
        uint256 expireAt = block.timestamp + 1 hours;
        uint8 isFree = 1; // Free mint
        bytes32 messageHash = controller.getMessageHash(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree
        );
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );

        // Sign the message hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Mint a new GitID NFT with free mint
        vm.prank(user);
        controller.mint(
            githubUsername,
            user,
            expireAt,
            chainId,
            isFree,
            signature
        );

        // Check if the user has received the token
        assertEq(
            gitID.ownerOf(gitID.getTokenIdByUsername(githubUsername)),
            user
        );
        assertEq(gitID.getUsernameByAddress(user), githubUsername);
    }

    function testWithdraw() public {
        // Deposit some ether to the contract
        vm.deal(address(controller), 1 ether);

        // Check initial balance of the owner
        uint256 initialOwnerBalance = owner.balance;

        // Withdraw ether from the contract
        controller.withdraw();

        // Check if the balance has been transferred to the owner
        assertEq(owner.balance, initialOwnerBalance + 1 ether);
    }
}
