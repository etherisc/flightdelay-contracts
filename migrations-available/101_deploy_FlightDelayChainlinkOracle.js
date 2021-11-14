const gif = require('@etherisc/gif-connect')

const log = console
const FlightDelayChainlink = artifacts.require('FlightDelayChainlink.sol')
const truffleConfig = require('../truffle-config')

module.exports = async (deployer, network /* , accounts */) => {
  const { gifRegistry, httpProvider } = truffleConfig.networks[network]
  const gifInstance = new gif.Instance(httpProvider, gifRegistry)
  const productServiceAddress = await gifInstance.getProductServiceAddress()
  // const producServiceConfig = await gifInstance.getContractConfig('ProductService')
  log.log(`ProductService Address: ${productServiceAddress}`)
  await deployer.deploy(FlightDelayChainlink, productServiceAddress)
}
