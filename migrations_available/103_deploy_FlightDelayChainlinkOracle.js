const gif = require('@etherisc/gif-connect')

const log = console
const FlightDelayChainlink = artifacts.require('FlightDelayChainlink.sol')

module.exports = async (deployer /* , network, accounts */) => {
  const gifInstance = new gif.Instance(process.env.HTTP_PROVIDER, process.env.GIF_REGISTRY)
  const productServiceAddress = await gifInstance.getProductServiceAddress()
  // const producServiceConfig = await gifInstance.getContractConfig('ProductService')
  log.log(`ProductService Address: ${productServiceAddress}`)
  await deployer.deploy(FlightDelayChainlink, productServiceAddress)
}
