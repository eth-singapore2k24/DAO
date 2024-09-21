// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAirDAOSBT is IERC721 {
    function mint(address to, string memory metadataURI) external returns (uint256);
    function tokenData(uint256 tokenId) external view returns (address owner, string memory metadataURI, bool isRevoked);
    function balanceOf(address owner) external view returns (uint256);
}

interface IAirDAOGovernanceToken is IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TempDecentralizedAdPlatform is ReentrancyGuard {
    IAirDAOSBT public immutable airDAOSBT; 
    IAirDAOGovernanceToken public immutable governanceToken;

    constructor(IAirDAOSBT _airDAOSBT, IAirDAOGovernanceToken _governanceToken) {
        airDAOSBT = _airDAOSBT;
        governanceToken = _governanceToken;
    }
}