#!/bin/bash

# Set project name
PROJECT_NAME="lux-bot"
CONTRACT_NAME="LuxAiGuide"
FRONTEND_DIR="$PROJECT_NAME/frontend"
BACKEND_DIR="$PROJECT_NAME/backend"
CONTRACTS_DIR="$PROJECT_NAME/contracts"
SCRIPTS_DIR="$PROJECT_NAME/scripts"
IPFS_DIR="$PROJECT_NAME/ipfs"

# Create main project folder
echo "Creating project folder: $PROJECT_NAME"
mkdir -p $PROJECT_NAME

# Create folders for frontend, backend, contracts, and IPFS
echo "Setting up folder structure..."
mkdir -p $FRONTEND_DIR/src $BACKEND_DIR $CONTRACTS_DIR $SCRIPTS_DIR $IPFS_DIR

# Initialize backend with Node.js
echo "Initializing backend..."
cd $BACKEND_DIR
npm init -y
npm install express body-parser web3 axios dotenv openai
touch server.js .env LuxAiGuideABI.json
cd ..

# Initialize frontend with React
echo "Setting up frontend with React..."
npx create-react-app $FRONTEND_DIR --template cra-template-pwa
cd $FRONTEND_DIR
npm install axios
touch src/MintGuide.js
cd ../..

# Initialize Hardhat for smart contracts
echo "Setting up Hardhat for smart contracts..."
cd $CONTRACTS_DIR
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat init
touch $CONTRACT_NAME.sol
cat > hardhat.config.js <<EOL
require('@nomicfoundation/hardhat-toolbox');

module.exports = {
    solidity: "0.8.0",
    networks: {
        solena: {
            url: "https://solena-mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID",
            accounts: ["YOUR_PRIVATE_KEY"]
        }
    }
};
EOL

# Create a basic smart contract
cat > $CONTRACT_NAME.sol <<EOL
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract $CONTRACT_NAME is ERC721 {
    struct Guide {
        string title;
        string description;
        string contentURI;
        address creator;
    }

    mapping(uint256 => Guide) public guides;
    uint256 public nextTokenId;

    constructor() ERC721("$CONTRACT_NAME", "LUXG") {}

    function mintGuide(string memory title, string memory description, string memory contentURI) public returns (uint256) {
        uint256 tokenId = nextTokenId++;
        guides[tokenId] = Guide(title, description, contentURI, msg.sender);
        _mint(msg.sender, tokenId);
        return tokenId;
    }
}
EOL
cd ..

# Create IPFS script
echo "Creating IPFS integration script..."
cat > $IPFS_DIR/upload_to_ipfs.js <<EOL
const { create } = require('ipfs-http-client');
const fs = require('fs');
const path = require('path');

// Initialize IPFS client
const ipfs = create('https://ipfs.infura.io:5001/api/v0');

async function uploadFile(filePath) {
    try {
        const file = fs.readFileSync(filePath);
        const added = await ipfs.add(file);
        console.log(\`File uploaded to IPFS with CID: \${added.path}\`);
        return added.path;
    } catch (error) {
        console.error('Error uploading file:', error);
    }
}

// Example usage
const filePath = path.resolve(__dirname, 'example.txt');
uploadFile(filePath);
EOL

# Add example IPFS file
echo "Adding example IPFS file..."
echo "This is a sample guide for Lux Bot." > $IPFS_DIR/example.txt

# Create deployment script for the contract
echo "Creating deployment script..."
cat > $SCRIPTS_DIR/deploy_contract.js <<EOL
const { ethers } = require("hardhat");

async function main() {
    const LuxAiGuide = await ethers.getContractFactory("$CONTRACT_NAME");
    const luxAiGuide = await LuxAiGuide.deploy();

    await luxAiGuide.deployed();
    console.log("Contract deployed to:", luxAiGuide.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
EOL

# Finalizing
echo "Project structure created successfully."
echo "Next steps:"
echo "1. Configure .env files in backend and hardhat.config.js for deployment."
echo "2. Run 'npx hardhat compile' and 'node scripts/deploy_contract.js' to deploy the contract."
echo "3. Start the backend server with 'node server.js' and frontend with 'npm start'."
