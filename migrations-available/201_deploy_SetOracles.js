const FlightDelayChainlink = artifacts.require('FlightDelayChainlink.sol')

module.exports = async (/* deployer, network , accounts */) => {
  const FlightDelayChainlinkContract = await FlightDelayChainlink.deployed()

  FlightDelayChainlinkContract.setOracles(
    web3.fromAscii('FlightRatings'), // bytes32 _ratingsOracleType,
    1, // uint256 _ratingsOracleId,
    web3.fromAscii('FlightStatuses'), // bytes32 _statusesOracleType,
    2, // uint256 _statusesOracleId
  )
}
