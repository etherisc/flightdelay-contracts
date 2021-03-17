const FlightDelayStaking = artifacts.require("FlightDelayStaking.sol");
const DIPTokenSokol = "0x19F6E3F48A7e04C292A2BB0B14312b79c0fa17E6";
const DIPTokenLocal = "0xD2f3b9ac26F296f9e843769ea0204FdF9E32347c";

module.exports = async deployer => {
  await deployer.deploy(FlightDelayStaking, DIPTokenLocal, { gas: 3500000 });
};
