const gif = require('@etherisc/gif-connect')
const { info } = require('../io/logger')

const FD = artifacts.require('FlightDelayChainlink.sol')
const s32b = web3.utils.fromAscii
const unixTime = (str) => new Date(str).getTime() / 1000
const toWei = (value) => web3.utils.toWei(value)

contract('FlightDelay', (accounts) => {
  it('should apply for a policy', async () => {
    const instance = new gif.Instance(
      process.env.HTTP_PROVIDER,
      process.env.GIF_REGISTRY,
      process.env.MNEMONIC,
    )
    const iosConf = await instance.getContractConfig('InstanceOperatorService')
    const ios = new web3.eth.Contract(iosConf.abi, iosConf.address)
    const fd = await FD.deployed()
    const productId = await fd.productId()
    info(`Using FlightDelay deployed at: ${fd.address}`)
    console.log(productId.toNumber())
    await ios.methods.approveProduct(productId.toNumber()).send({ from: accounts[0] })

    const tx = await fd.applyForPolicy(
      s32b('LH117'),
      s32b('2021/07/30'),
      unixTime('2021-07-30'),
      unixTime('2021-07-31'),
      [0, 0, 30, 50, 50],
      {
        value: toWei('1'),
        gasLimit: 5000000,
      },
    )
    console.log(JSON.stringify(await instance.getDecodedLogs({ logs: tx.receipt.rawLogs }), null, 2))
    console.log(JSON.stringify(tx.logs, null, 2))
  })
})
