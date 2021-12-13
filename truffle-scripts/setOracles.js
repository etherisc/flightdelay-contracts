const FlightDelayChainlink = artifacts.require('FlightDelayChainlink')

// eslint-disable-next-line no-console
const info = console.log

module.exports = async (callback) => {
  try {
    const fd = await FlightDelayChainlink.deployed()
    info(`Using FlightDelayChainlink at ${fd.address}`)

    const tx = await fd.setOracles(
      web3.utils.asciiToHex('FlightRatings'),
      5,
      web3.utils.asciiToHex('FlightStatuses'),
      8,
    )
    info('Transaction: ', tx)
    callback()
  } catch (error) {
    info(error)
    callback(error)
  }
}
