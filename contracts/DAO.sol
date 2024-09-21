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

contract DecentralizedAdPlatform is ReentrancyGuard {
    IAirDAOSBT public immutable airDAOSBT; 
    IAirDAOGovernanceToken public immutable governanceToken;

    uint256 public campaignIdCounter; 
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => AdvertiserProfile) public advertiserProfiles;

    uint256 public votingPeriod = 1 days; 
    uint256 public minimumQuorum = 1000; 

    enum CampaignStatus { Proposed, Voting, Approved, Rejected, Active, Ended }
    enum AdvertiserTier { Bronze, Silver, Gold, Platinum }

    struct Campaign {
        address advertiser;
        string campaignURI;
        uint256 minReputation;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;
        uint256 amountSpent;
        CampaignStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
        string privateLabel;
        string publicLabel;
        AdvertiserTier tier;
    }

    struct AdvertiserProfile {
        uint256 reputation;
        AdvertiserTier tier;
        uint256 campaignsProposed;
        uint256 campaignsApproved;
        uint256 sbtTokenId;
    }

    event CampaignProposed(uint256 campaignId, address advertiser, string campaignURI, AdvertiserTier tier);
    event CampaignApproved(uint256 campaignId);
    event CampaignRejected(uint256 campaignId);
    event AdvertiserTierUpdated(address advertiser, AdvertiserTier newTier);
    event ReputationUpdated(address advertiser, uint256 newReputation);

    constructor(address _airDAOSBTAddress, address _governanceTokenAddress) {
        require(_airDAOSBTAddress != address(0), "Invalid AirDAOSBT address");
        require(_governanceTokenAddress != address(0), "Invalid governance token address");

        airDAOSBT = IAirDAOSBT(_airDAOSBTAddress); 
        governanceToken = IAirDAOGovernanceToken(_governanceTokenAddress);
    }

    function proposeCampaign(
        string memory _campaignURI,
        uint256 _minReputation,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _budget,
        string memory _privateLabel,
        string memory _publicLabel,
        string memory _metadataURI,
        uint256 _reputation
    ) public {
        require(bytes(_campaignURI).length > 0, "Campaign URI cannot be empty");
        require(_endTime > _startTime, "End time must be after start time");
        require(_budget > 0, "Budget must be greater than zero");

        AdvertiserProfile storage profile = advertiserProfiles[msg.sender];
        updateAdvertiserProfile(msg.sender, _metadataURI, _reputation);

        require(profile.reputation >= _minReputation, "Insufficient reputation");

        uint256 campaignId = campaignIdCounter++;
        campaigns[campaignId] = Campaign({
            advertiser: msg.sender,
            campaignURI: _campaignURI,
            minReputation: _minReputation,
            startTime: _startTime,
            endTime: _endTime,
            budget: _budget,
            amountSpent: 0,
            status: CampaignStatus.Voting,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingPeriod,
            privateLabel: _privateLabel,
            publicLabel: _publicLabel,
            tier: profile.tier
        });

        profile.campaignsProposed++;

        emit CampaignProposed(campaignId, msg.sender, _campaignURI, profile.tier);
    }

    function voteOnCampaign(uint256 _campaignId, bool _approve) public {
        require(_campaignId < campaignIdCounter, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.Voting, "Campaign is not in voting stage");
        require(block.timestamp <= campaign.votingEndTime, "Voting period is over");
        require(!hasVoted[_campaignId][msg.sender], "Already voted");

        uint256 voterBalance = governanceToken.balanceOf(msg.sender);
        require(voterBalance > 0, "No voting rights");

        uint256 votePower = calculateVotePower(voterBalance);

        if (_approve) {
            campaign.votesFor += votePower; 
        } else {
            campaign.votesAgainst += votePower;
        }

        hasVoted[_campaignId][msg.sender] = true;
    }

    function executeVotingResult(uint256 _campaignId, string memory newMetadataURI) public {
        require(_campaignId < campaignIdCounter, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.Voting, "Campaign is not in voting stage");
        require(block.timestamp > campaign.votingEndTime, "Voting period not over");

        uint256 totalVotes = campaign.votesFor + campaign.votesAgainst;
        require(totalVotes >= minimumQuorum, "Quorum not reached");

        AdvertiserProfile storage profile = advertiserProfiles[campaign.advertiser];

        if (campaign.votesFor > campaign.votesAgainst) {
            campaign.status = CampaignStatus.Approved;
            profile.campaignsApproved++;
            updateAdvertiserReputation(campaign.advertiser, 10, newMetadataURI); // Reward for approved campaign
            emit CampaignApproved(_campaignId);
        } else {
            campaign.status = CampaignStatus.Rejected;
            updateAdvertiserReputation(campaign.advertiser, -5, newMetadataURI); // Penalty for rejected campaign
            emit CampaignRejected(_campaignId);
        }

        updateAdvertiserTier(campaign.advertiser);
    }


    function getVotingResult(uint256 _campaignId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        require(_campaignId < campaignIdCounter, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.Voting, "Campaign is not in voting stage");
        require(block.timestamp > campaign.votingEndTime, "Voting period not over");

        uint256 totalVotes = campaign.votesFor + campaign.votesAgainst;
        require(totalVotes >= minimumQuorum, "Quorum not reached");
        return (campaign.votesFor, campaign.votesAgainst);
    }


    function updateAdvertiserProfile(address advertiser, string memory newMetadataURI, uint256 newReputation) public {
        AdvertiserProfile storage profile = advertiserProfiles[advertiser];
        uint256 sbtBalance = airDAOSBT.balanceOf(advertiser);

        if (sbtBalance == 0) {
            uint256 newTokenId = airDAOSBT.mint(advertiser, newMetadataURI);
            profile.sbtTokenId = newTokenId;
        } else if (profile.sbtTokenId == 0) {
            profile.sbtTokenId = findAdvertiserSBTTokenId(advertiser);
            airDAOSBT.mint(advertiser, newMetadataURI);
        } else {
            airDAOSBT.mint(advertiser, newMetadataURI);
        }

        profile.reputation = newReputation;
        updateAdvertiserTier(advertiser);

        emit ReputationUpdated(advertiser, newReputation);
    }

    function updateAdvertiserReputation(address advertiser, int256 reputationChange, string memory newMetadataURI) internal {
        AdvertiserProfile storage profile = advertiserProfiles[advertiser];
        if (reputationChange > 0) {
            profile.reputation += uint256(reputationChange);
        } else {
            profile.reputation = profile.reputation > uint256(-reputationChange) ? profile.reputation - uint256(-reputationChange) : 0;
        }

        airDAOSBT.mint(advertiser, newMetadataURI); // This will update the existing SBT's metadata

        emit ReputationUpdated(advertiser, profile.reputation);
    }

    function updateAdvertiserTier(address advertiser) internal {
        AdvertiserProfile storage profile = advertiserProfiles[advertiser];
        AdvertiserTier newTier;

        if (profile.reputation >= 10000) {
            newTier = AdvertiserTier.Platinum;
        } else if (profile.reputation >= 5000) {
            newTier = AdvertiserTier.Gold;
        } else if (profile.reputation >= 1000) {
            newTier = AdvertiserTier.Silver;
        } else {
            newTier = AdvertiserTier.Bronze;
        }

        if (newTier != profile.tier) {
            profile.tier = newTier;
            emit AdvertiserTierUpdated(advertiser, newTier);
        }
    }

    function calculateVotePower(uint256 balance) internal pure returns (uint256) {
        return Math.sqrt(balance); // Simple quadratic voting
    }

    function getAdvertiserBenefits(address advertiser) public view returns (uint256 discountPercentage, uint256 maxCampaigns) {
        AdvertiserTier tier = advertiserProfiles[advertiser].tier;
        
        if (tier == AdvertiserTier.Platinum) {
            return (20, 10); // 20% discount, max 10 concurrent campaigns
        } else if (tier == AdvertiserTier.Gold) {
            return (15, 7); // 15% discount, max 7 concurrent campaigns
        } else if (tier == AdvertiserTier.Silver) {
            return (10, 5); // 10% discount, max 5 concurrent campaigns
        } else {
            return (0, 3); // No discount, max 3 concurrent campaigns
        }
    }


    function findAdvertiserSBTTokenId(address advertiser) internal view returns (uint256) {
        for (uint256 i = 1; i <= airDAOSBT.balanceOf(advertiser); i++) {
            if (airDAOSBT.ownerOf(i) == advertiser) {
                return i;
            }
        }
        revert("SBT not found for advertiser");
    }
}