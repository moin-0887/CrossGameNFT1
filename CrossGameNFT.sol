// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title CrossGameNFT
 * @dev A smart contract that enables NFTs with cross-game utility
 */
contract CrossGameNFT is ERC721URIStorage, Ownable(msg.sender) {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // Mapping from game ID to token ID to utility data
    mapping(string => mapping(uint256 => string)) private _gameUtilities;
    
    // List of authorized game contracts that can update utility
    mapping(string => address) private _authorizedGames;
    
    // Events
    event UtilityUpdated(uint256 tokenId, string gameId, string utilityData);
    event GameAuthorized(string gameId, address gameAddress);

    constructor() ERC721("CrossGameNFT", "CGNFT") {}
    
    /*
     * @dev Mint a new NFT with cross-game utility
     * @param recipient The address that will own the minted NFT
     * @param tokenURI The URI containing metadata about the NFT
     * @param gameUtilities Array of game IDs and corresponding utility data
     * @return The ID of the newly minted NFT
     */
    function mintNFT(
        address recipient, 
        string memory tokenURI,
        string[] memory gameIds,
        string[] memory utilities
    ) 
        public 
        onlyOwner 
        returns (uint256) 
    {
        require(gameIds.length == utilities.length, "Game IDs and utilities arrays must be the same length");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        // Set initial utilities for each game
        for (uint256 i = 0; i < gameIds.length; i++) {
            _gameUtilities[gameIds[i]][newTokenId] = utilities[i];
            emit UtilityUpdated(newTokenId, gameIds[i], utilities[i]);
        }
        
        return newTokenId;
    }
    
    /**
     * @dev Authorize a game to update utility data for NFTs
     * @param gameId Unique identifier for the game
     * @param gameAddress Address of the game's contract
     */
    function authorizeGame(string memory gameId, address gameAddress) public onlyOwner {
        _authorizedGames[gameId] = gameAddress;
        emit GameAuthorized(gameId, gameAddress);
    }
    
    /**
     * @dev Update utility data for an NFT in a specific game
     * @param tokenId ID of the NFT to update
     * @param gameId Identifier of the game being updated
     * @param utilityData New utility data for the NFT in the game
     */
    function updateUtility(uint256 tokenId, string memory gameId, string memory utilityData) public {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(
            msg.sender == _authorizedGames[gameId] || msg.sender == owner(),
            "Caller is not authorized for this game"
        );
        
        _gameUtilities[gameId][tokenId] = utilityData;
        emit UtilityUpdated(tokenId, gameId, utilityData);
    }
    
    /*
     * @dev Get utility data for an NFT in a specific game
     * @param tokenId ID of the NFT
     * @param gameId Identifier of the game
     * @return Utility data for the NFT in the specified game
     */
    function getUtility(uint256 tokenId, string memory gameId) public view returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _gameUtilities[gameId][tokenId];
    }
}
