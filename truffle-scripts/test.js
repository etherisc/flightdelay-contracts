const FlightDelayChainlink = artifacts.require('FlightDelayChainlink')
const axios = require('axios')

// eslint-disable-next-line no-console
const info = console.log
const ratingsEndpoint = 'https://fs-api.etherisc.com/api/v1/ratings-oracle'
const getQuote = async (carrierFlightNumber) => {
  const result = await axios.get(ratingsEndpoint, { data: { carrierFlightNumber } })
  info(result.data)
  return result
}

module.exports = async (callback) => {
  try {
    const fd = await FlightDelayChainlink.deployed()
    info(fd.address)

    const carrierFlightNumber = 'LH/117'
    const premium = '0.1'
    const departureYearMonthDay = '2021/11/23'
    const departureTime = new Date(departureYearMonthDay) / 1000
    const departureTimeBN = new web3.utils.BN(departureTime)
    const arrivalTimeBN = new web3.utils.BN(departureTime + 3600)

    const { data } = await getQuote(carrierFlightNumber)
    const statistics = [data.observations, data.late15, data.late30, data.late45, data.cancelled, data.diverted]
      .map((num) => new web3.utils.BN(num))
    const payoutResult = await fd.calculatePayouts(web3.utils.toWei(premium), statistics)
    info('Payoutoptions: ', payoutResult._payoutOptions.map((bn) => bn.toString()))

    const tx = await fd.applyForPolicy(
      web3.utils.asciiToHex(carrierFlightNumber),
      web3.utils.asciiToHex(departureYearMonthDay),
      departureTimeBN,
      arrivalTimeBN,
      payoutResult._payoutOptions,
      { value: web3.utils.toWei(premium) },
    )
    info('Transaction: ', tx)
    callback()
  } catch (error) {
    info(error)
    callback(error)
  }
}
