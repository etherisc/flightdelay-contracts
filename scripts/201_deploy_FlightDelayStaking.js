// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const DIPTokenAddress = {
  77: "0x19F6E3F48A7e04C292A2BB0B14312b79c0fa17E6"
};

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const FlightDelayStaking = await hre.ethers.getContractFactory(
    "FlightDelayStaking"
  );
  const flightDelayStaking = await FlightDelayStaking.deploy(
    DIPTokenAddress["77"]
  );

  await flightDelayStaking.deployed();

  console.log("FlightDelayStaking deployed to:", flightDelayStaking.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
