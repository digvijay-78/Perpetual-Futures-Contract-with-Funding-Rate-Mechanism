const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("PerpetualFutures");
  const contract = await Contract.deploy(1000, 50); // Initial price = 1000, funding rate = 0.5%/hour
  await contract.deployed();
  console.log("PerpetualFutures deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
