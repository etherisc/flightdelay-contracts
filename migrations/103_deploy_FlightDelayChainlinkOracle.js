const gif = require('@etherisc/gif-connect')

const FlightDelayChainlink = artifacts.require('FlightDelayChainlink.sol')

module.exports = async (deployer /*, network, accounts */) => {

  const gifInstance = new gif.Instance(process.env.HTTP_PROVIDER, process.env.GIF_REGISTRY)
  const productServiceAddress = await gifInstance.getProductServiceAddress()
  console.log(`ProductService Address: ${productServiceAddress}`)
  await deployer.deploy(FlightDelayChainlink, productServiceAddress)

}
