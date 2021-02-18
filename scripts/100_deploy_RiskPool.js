const hre = require("hardhat");

async function main() {
  const RiskPool = await hre.ethers.getContractFactory("RiskPool");
  const riskPool = await RiskPool.deploy();

  await riskPool.deployed();

  console.log("RiskPool deployed to:", riskPool.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
