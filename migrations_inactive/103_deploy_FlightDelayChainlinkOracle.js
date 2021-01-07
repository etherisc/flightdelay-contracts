
const FlightDelayChainlink = artifacts.require('FlightDelayChainlink.sol');
const productServiceAddress = '0x6520354fa128cc6483B9662548A597f7FcB7a687';


module.exports = async (deployer) => {
  await deployer.deploy(FlightDelayChainlink, productServiceAddress, { gas: 3500000 });
};
