// Metadata: {"genericLabels": {}, "reputation": 10"}
import React from "react"
import {ethers} from 'ethers'
import lighthouse from '@lighthouse-web3/sdk'
const apiKey = "YOUR_API_KEY"

const signAuthMessage = async (publicKey, privateKey) => {
  const provider = new ethers.JsonRpcProvider('**RPC_ENDPOINT**');
  const signer = new ethers.Wallet(privateKey, provider);
  const messageRequested = (await lighthouse.getAuthMessage(publicKey)).data.message;
  const signedMessage = await signer.signMessage(messageRequested);
  return signedMessage;
};

const parseMetadata = (metadata) => {
  const { genericLabels, reputation } = metadata;
  return { genericLabels, reputation };
}

const uploadMetadataToLighthouse = async (genericLabels, reputation, publicKey, privateKey) => {
  try {
    const metadata = {"genericLabels": genericLabels, "reputation": reputation}
    const metadataString = JSON.stringify(metadata);
    const signedMessage = await signAuthMessage(publicKey, privateKey);
    const response = await lighthouse.textUploadEncrypted(metadataString, apiKey, publicKey, signedMessage);
    console.log('Text uploaded successfully:', response);
    return response;
  } catch (error) {
    console.error('Failed to upload encrypted text:', error);
    throw error;
  }
}

const getMetadataFromLighthouse = async (cid, publicKey, privateKey) => {
    const signedMessage = await signAuthMessage(publicKey, privateKey)
    const fileEncryptionKey = await lighthouse.fetchEncryptionKey(
        cid,
        publicKey,
        signedMessage
    )

    const decrypted = await lighthouse.decryptFile(
        cid,
        fileEncryptionKey.data.key
    )

    return JSON.parse(decrypted)
}


const AIRDaoSBTContractAddress = "0xF70E96bD5A046062Ce21DF698754bFba9f461F2a"
const AIRDaoSBTContractABI = []

const DAOContractAddess = "0x586EE5Df24c5a426e42eD7Ea6e3EB0f00a4a2256"
const DAOContractABI = []


async function getContract() {
  if (typeof window.ethereum !== 'undefined') {
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    return new ethers.Contract(contractAddress, contractABI, signer);
  }
}

async function proposeCampaign(campaignURI, minReputation, startTime, endTime, budget, privateLabel, publicLabel, metadataURI, reputation) {
  const contract = await getContract();
  try {
    const tx = await contract.proposeCampaign(
      campaignURI,
      minReputation,
      startTime,
      endTime,
      budget,
      privateLabel,
      publicLabel,
      metadataURI,
      reputation
    );
    await tx.wait();
    console.log("Campaign proposed successfully");
  } catch (error) {
    console.error("Error proposing campaign:", error);
  }
}

async function voteOnCampaign(campaignId, approve) {
  const contract = await getContract();
  try {
    const tx = await contract.voteOnCampaign(campaignId, approve);
    await tx.wait();
    console.log("Vote cast successfully");
  } catch (error) {
    console.error("Error voting on campaign:", error);
  }
}

async function executeVotingResult(campaignId, newMetadataURI) {
  const contract = await getContract();
  try {
    const tx = await contract.executeVotingResult(campaignId, newMetadataURI);
    await tx.wait();
    console.log("Voting result executed successfully");
  } catch (error) {
    console.error("Error executing voting result:", error);
  }
}

async function getVotingResult(campaignId) {
  const contract = await getContract();
  try {
    const result = await contract.getVotingResult(campaignId);
    console.log("Votes For:", result[0].toString());
    console.log("Votes Against:", result[1].toString());
    return result;
  } catch (error) {
    console.error("Error getting voting result:", error);
  }
}

async function getAdvertiserBenefits(advertiserAddress) {
  const contract = await getContract();
  try {
    const benefits = await contract.getAdvertiserBenefits(advertiserAddress);
    console.log("Discount Percentage:", benefits[0].toString());
    console.log("Max Campaigns:", benefits[1].toString());
    return benefits;
  } catch (error) {
    console.error("Error getting advertiser benefits:", error);
  }
}




