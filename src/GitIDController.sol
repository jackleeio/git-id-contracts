// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./GitID.sol";

/**
 * @title GitIDController
 * @dev A controller contract for managing GitID NFTs. This contract handles the minting and burning of GitID NFTs.
 * It uses signatures to verify the authenticity of mint requests.
 */
contract GitIDController is Ownable {
    using ECDSA for bytes32;

    // Reference to the GitID contract
    GitID public gitID;
    // Address of the signer who is authorized to sign minting messages
    address public signer;

    // Event emitted when the signer address is changed
    event SignerChanged(address indexed oldSigner, address indexed newSigner);

    /**
     * @dev Constructor sets the GitID contract address and the initial signer address.
     * @param gitIDAddress The address of the GitID contract.
     * @param signerAddress The initial signer address.
     */
    constructor(
        address gitIDAddress,
        address signerAddress
    ) Ownable(msg.sender) {
        gitID = GitID(gitIDAddress);
        signer = signerAddress;
    }

    /**
     * @dev Computes the message hash for a given GitHub username, chain ID, and user address.
     * @param githubUsername The GitHub username.
     * @param chainId The chain ID.
     * @param user The user's address.
     * @return The computed message hash.
     */
    function getMessageHash(
        string memory githubUsername,
        uint256 chainId,
        address user
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(githubUsername, ".git", chainId, user));
    }

    /**
     * @dev Verifies the signature for a given hash.
     * @param hash The hash of the message.
     * @param signature The signature to verify.
     * @return True if the signature is valid, false otherwise.
     */
    function verify(
        bytes32 hash,
        bytes memory signature
    ) public view returns (bool) {
        return ECDSA.recover(hash, signature) == signer;
    }

    /**
     * @dev Mints a new GitID NFT if the provided signature is valid.
     * @param githubUsername The GitHub username to be associated with the GitID NFT.
     * @param chainId The chain ID.
     * @param user The address of the user who will receive the GitID NFT.
     * @param signature The signature to verify the mint request.
     */
    function mint(
        string memory githubUsername,
        uint256 chainId,
        address user,
        bytes memory signature
    ) external {
        bytes32 messageHash = getMessageHash(githubUsername, chainId, user);
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            messageHash
        );
        require(verify(ethSignedMessageHash, signature), "Invalid signature");

        gitID.mint(user, githubUsername);
    }

    /**
     * @dev Burns a GitID NFT owned by the specified user.
     * @param user The address of the user whose GitID NFT will be burned.
     */
    function burn(address user) external onlyOwner {
        gitID.burn(user);
    }

    /**
     * @dev Sets a new signer address.
     * @param newSigner The new signer address.
     */
    function setSigner(address newSigner) external onlyOwner {
        address oldSigner = signer;
        signer = newSigner;
        emit SignerChanged(oldSigner, newSigner);
    }
}
