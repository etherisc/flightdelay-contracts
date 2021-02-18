const hre = require("hardhat");

const DIPTokenAddress = {
  77: "0x19F6E3F48A7e04C292A2BB0B14312b79c0fa17E6"
};

async function main() {
  const FlightDelayStaking = await hre.ethers.getContractFactory(
    "FlightDelayStaking"
  );
  const flightDelayStaking = await FlightDelayStaking.deploy(
    DIPTokenAddress["77"]
  );

  await flightDelayStaking.deployed();

  console.log("FlightDelayStaking deployed to:", flightDelayStaking.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
