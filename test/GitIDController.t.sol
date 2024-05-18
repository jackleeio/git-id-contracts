// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GitIDController.sol";
import "../src/GitID.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract GitIDControllerTest is Test {
    GitIDController public controller;
    GitID public gitID;
    address public owner;
    address public signer;
    address public user;
    bytes32 public messageHash;
    bytes32 public ethSignedMessageHash;
    bytes public validSignature;
    bytes public invalidSignature;

    uint256 internal userPrivateKey;
    uint256 internal signerPrivateKey;

    function setUp() public {
        owner = address(this);
        userPrivateKey = 0xa11ce;
        signerPrivateKey = 0xabc123;

        user = vm.addr(userPrivateKey);
        signer = vm.addr(signerPrivateKey);

        // 部署合约
        gitID = new GitID();
        controller = new GitIDController(address(gitID), owner);
        gitID.transferOwnership(address(controller));

        // 给测试账户分配资金
        vm.deal(user, 1 ether);
        vm.deal(owner, 1 ether);
        

        console.logAddress(user);
        console.log(block.chainid);


        // 设置有效的签名
        messageHash = controller.getMessageHash(
            "testuser",
            user, 
            block.chainid,
            1
        );

        // 计算 ethSignedMessageHash
        ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );

        // 生成有效的签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPrivateKey, // Use the correct private key for signing
            ethSignedMessageHash
        );
        validSignature = abi.encodePacked(r, s, v);


        // 无效的签名
        invalidSignature = hex"1234"; // 无效的签名

        // 打印调试信息
        console.logAddress(signer);
        console.logBytes32(messageHash);
        console.logBytes32(ethSignedMessageHash);
        console.logBytes(validSignature);
    }

    function testSetSigner() public {
        vm.prank(owner);
        controller.setSigner(signer);
        assertEq(controller.signer(), signer);
    }

    function testSetMintFee() public {
        vm.prank(owner);
        controller.setMintFee(0.1 ether);
        assertEq(controller.mintFee(), 0.1 ether);
    }

    function testMintWithValidSignature() public {
        // 打印当前签名者地址
        console.logAddress(controller.signer());

        controller.mint{value: 0.069 ether}(
            "testuser",
            user,
            block.chainid,
            1,
            validSignature
        );
        assertEq(gitID.getUsernameByAddress(user), "testuser");
    }

    function testMintWithInvalidSignature() public {
        vm.expectRevert("Invalid signature");
        vm.prank(user);
        controller.mint{value: 0.069 ether}(
            "testuser",
            user,
            block.chainid,
            0,
            invalidSignature
        );
    }

    function testFirstMintIsFree() public {
        vm.prank(user);
        controller.mint("testuser", user, block.chainid, 1, validSignature);
        assertEq(gitID.getUsernameByAddress(user), "testuser");
    }

    function testNonFirstMintFee() public {
        vm.prank(user);
        controller.mint{value: 0.069 ether}(
            "testuser",
            user,
            block.chainid,
            0,
            validSignature
        );
        assertEq(gitID.getUsernameByAddress(user), "testuser");

        // 尝试再次铸造，应该需要支付费用
        vm.expectRevert("Mint fee is 0.069 ether");
        vm.prank(user);
        controller.mint("testuser2", user, block.chainid, 0, validSignature);
    }

    function testBurn() public {
        vm.prank(user);
        controller.mint{value: 0.069 ether}(
            "testuser",
            user,
            block.chainid,
            0,
            validSignature
        );

        vm.prank(owner);
        controller.burn(user);
        assertEq(gitID.getUsernameByAddress(user), "");
    }
}
