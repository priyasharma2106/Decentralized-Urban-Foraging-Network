const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying UrbanForagingNetwork contract to Core Blockchain...");

  // Get the contract factory
  const UrbanForagingNetwork = await ethers.getContractFactory("UrbanForagingNetwork");

  // Deploy the contract
  const urbanForagingNetwork = await UrbanForagingNetwork.deploy();

  // Wait for the contract to be deployed
  await urbanForagingNetwork.deployed();

  console.log("UrbanForagingNetwork contract deployed to:", urbanForagingNetwork.address);
  console.log("Transaction hash:", urbanForagingNetwork.deployTransaction.hash);

  // Verify deployment
  console.log("Verifying deployment...");
  const deployedCode = await ethers.provider.getCode(urbanForagingNetwork.address);
  if (deployedCode === "0x") {
    console.log("❌ Contract deployment failed - no code at address");
  } else {
    console.log("✅ Contract successfully deployed and verified");
  }

  // Display contract details
  console.log("\n=== Contract Details ===");
  console.log("Contract Address:", urbanForagingNetwork.address);
  console.log("Network: Core Testnet");
  console.log("Chain ID: 1114");
  console.log("Deployer Address:", (await ethers.getSigners())[0].address);
  
  // Test basic contract functionality
  try {
    const nextLocationId = await urbanForagingNetwork.nextLocationId();
    console.log("Initial nextLocationId:", nextLocationId.toString());
    console.log("✅ Contract is functional and ready to use");
  } catch (error) {
    console.log("❌ Error testing contract functionality:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
