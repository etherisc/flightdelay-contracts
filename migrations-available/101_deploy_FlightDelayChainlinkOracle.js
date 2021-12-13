const gif = require('@etherisc/gif-connect')

const log = console
const FlightDelayChainlink = artifacts.require('FlightDelayChainlink.sol')
const truffleConfig = require('../truffle-config')

module.exports = async (deployer, network /* , accounts */) => {
  const { gifRegistry, httpProvider } = truffleConfig.networks[network]
  const gifInstance = new gif.Instance(httpProvider, gifRegistry)
  const productServiceAddress = await gifInstance.getProductServiceAddress()
  log.log(`ProductService Address: ${productServiceAddress}`)
  await deployer.deploy(
    FlightDelayChainlink,
    productServiceAddress,
    web3.utils.asciiToHex('FlightRatings'),
    5,
    web3.utils.asciiToHex('FlightStatuses'),
    8,
  )
}
