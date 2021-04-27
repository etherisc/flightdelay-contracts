
const FlightDelayStaking = artifacts.require('FlightDelayStaking.sol');
const DIPTokenSokol = '0x19F6E3F48A7e04C292A2BB0B14312b79c0fa17E6';


module.exports = async (deployer) => {
  await deployer.deploy(FlightDelayStaking, DIPTokenSokol, { gas: 3500000 });
};
