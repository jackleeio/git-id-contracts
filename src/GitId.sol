// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GitID is ERC721, Ownable {
    using ECDSA for bytes32;

    mapping(string => address) public githubToAddress;
    mapping(address => uint256) public addressToTokenId;

    event Mint(address indexed user, string githubUsername);
    event Burn(address indexed user, string githubUsername);

    constructor() ERC721("GitID", "GITID") {}

    function mint(
        string memory githubUsername,
        uint256 chainId,
        address user,
        bytes memory signature
    ) public {
        require(
            githubToAddress[githubUsername] == address(0),
            "GitID: Username already taken"
        );

        // Construct the message
        bytes32 message = keccak256(
            abi.encodePacked(githubUsername, ".git", chainId, user)
        ).toEthSignedMessageHash();

        // Verify the signature
        address signer = message.recover(signature);
        require(signer == user, "GitID: Invalid signature");

        // Generate tokenId
        uint256 tokenId = uint256(
            keccak256(abi.encodePacked(githubUsername, ".git"))
        );

        // Burn old GitID if exists
        if (addressToTokenId[user] != 0) {
            _burnGitID(user);
        }

        // Mint new GitID
        _mint(user, tokenId);

        githubToAddress[githubUsername] = user;
        addressToTokenId[user] = tokenId;

        emit Mint(user, githubUsername);
    }

    function burn() public {
        require(addressToTokenId[msg.sender] != 0, "GitID: No GitID to burn");

        _burnGitID(msg.sender);
    }

    function _burnGitID(address user) internal {
        uint256 tokenId = addressToTokenId[user];
        string memory githubUsername = _tokenIdToUsername(tokenId);

        _burn(tokenId);

        delete githubToAddress[githubUsername];
        delete addressToTokenId[user];

        emit Burn(user, githubUsername);
    }

    function _tokenIdToUsername(
        uint256 tokenId
    ) internal pure returns (string memory) {
        // Extract the username from the tokenId.
        // This is a simplified example and might need customization based on your actual encoding method.
        return string(abi.encodePacked(tokenId));
    }
}
