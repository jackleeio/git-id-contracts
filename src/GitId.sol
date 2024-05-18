// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GitID
 * @dev A contract for managing GitID NFTs. This contract handles the minting and burning of GitID NFTs.
 * Each GitID NFT is associated with a unique GitHub username.
 */
contract GitID is ERC721, Ownable {
    // Mapping from GitHub username to address
    mapping(string => address) public githubToAddress;
    // Mapping from address to tokenId
    mapping(address => uint256) public addressToTokenId;

    // Event emitted when a new GitID is minted
    event Mint(address indexed user, string githubUsername);
    // Event emitted when a GitID is burned
    event Burn(address indexed user, string githubUsername);

    /**
     * @dev Constructor initializes the ERC721 token with a name and a symbol.
     */
    constructor() ERC721("GitID", "GITID") Ownable(msg.sender) {}

    /**
     * @dev Mints a new GitID NFT if the GitHub username is not already taken.
     * If the user already has a GitID, it burns the old one before minting a new one.
     * @param user The address of the user who will receive the GitID NFT.
     * @param githubUsername The GitHub username to be associated with the GitID NFT.
     */
    function mint(
        address user,
        string memory githubUsername
    ) external onlyOwner {
        require(
            githubToAddress[githubUsername] == address(0),
            "GitID: Username already taken"
        );

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

        // Update mappings
        githubToAddress[githubUsername] = user;
        addressToTokenId[user] = tokenId;

        emit Mint(user, githubUsername);
    }

    /**
     * @dev Burns a GitID NFT owned by the specified user.
     * @param user The address of the user whose GitID NFT will be burned.
     */
    function burn(address user) external onlyOwner {
        require(addressToTokenId[user] != 0, "GitID: No GitID to burn");

        _burnGitID(user);
    }

    /**
     * @dev Internal function to burn a GitID NFT.
     * @param user The address of the user whose GitID NFT will be burned.
     */
    function _burnGitID(address user) internal {
        uint256 tokenId = addressToTokenId[user];
        string memory githubUsername = _tokenIdToUsername(tokenId);

        _burn(tokenId);

        // Update mappings
        delete githubToAddress[githubUsername];
        delete addressToTokenId[user];

        emit Burn(user, githubUsername);
    }

    /**
     * @dev Internal function to convert a tokenId to a GitHub username.
     * @param tokenId The tokenId to be converted.
     * @return The GitHub username associated with the tokenId.
     */
    function _tokenIdToUsername(
        uint256 tokenId
    ) internal pure returns (string memory) {
        // Extract the username from the tokenId.
        // This is a simplified example and might need customization based on your actual encoding method.
        return string(abi.encodePacked(tokenId));
    }
}
