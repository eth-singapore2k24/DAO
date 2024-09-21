// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AirDAOSBT is ERC721 {
    uint256 private _tokenIdCounter;

    mapping(uint256 => TokenData) public tokenData;

    struct TokenData {
        address owner; // Address of the token owner
        string metadataURI; // URI pointing to token metadata (off-chain)
        bool isRevoked; // Flag indicating if the token is revoked
    }

    constructor() ERC721("AirDAO Soulbound Token", "ASBT") {
        _tokenIdCounter = 1; 
    }

    function mint(address to, string memory metadataURI) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter++; 

        tokenData[tokenId] = TokenData({
            owner: to,
            metadataURI: metadataURI,
            isRevoked: false
        });

        _safeMint(to, tokenId);
        return tokenId;
    }

    function revoke(uint256 tokenId) public {
        require(msg.sender == tokenData[tokenId].owner, "Only the token owner can revoke it");
        tokenData[tokenId].isRevoked = true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("Soulbound tokens are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("Soulbound tokens are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        revert("Soulbound tokens are non-transferable");
    }

    
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        revert("Soulbound tokens are non-transferable");
    }
    

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(!tokenData[tokenId].isRevoked, "Token has been revoked");

        return tokenData[tokenId].metadataURI;
    }

        
    function getTokenData(uint256 tokenId) external view returns (address owner, string memory metadataURI, bool isRevoked) {
        require(_exists(tokenId), "Token does not exist");
        TokenData storage data = tokenData[tokenId];
        return (data.owner, data.metadataURI, data.isRevoked);
    }
}