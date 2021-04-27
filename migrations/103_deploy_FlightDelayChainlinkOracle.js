const { info } = require('../io/logger')
const Gifcli = require('@etherisc/gifcli')

const FlightDelayChainlink = artifacts.require('FlightDelayChainlink.sol')

module.exports = async (deployer, networks, accounts) => {

  const from = accounts[0]
  info(`Connecting to GIF: ${process.env.GIF_API_HOST}:${process.env.GIF_API_PORT}`)

  const gif = await Gifcli.connect()

  const { address: productServiceAddress } = await gif.artifact.get('platform', 'development', 'ProductService')

  const FlightDelay = await deployer.deploy(FlightDelayChainlink, productServiceAddress, { gas: 3500000 })
  const productId = (await FlightDelay.productId.call()).toNumber()

  const { abi: iosAbi, address: iosAddress } = await gif.artifact.get('platform', 'development', 'InstanceOperatorService')

  const instanceOperatorService = new web3.eth.Contract(
    JSON.parse(JSON.parse(iosAbi)),
    iosAddress
  )
  info(`Approve Product ${productId}`)
  await instanceOperatorService.methods.approveProduct(productId)
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`))
}
