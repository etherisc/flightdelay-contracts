const Gifcli = require('@etherisc/gifcli');
const { info } = require('../io/logger');

// const FlightDelayEtheriscOracle = artifacts.require('FlightDelayEtheriscOracle.sol');
const FlightDelayEtheriscOracle = artifacts.require('FlightDelayMockup.sol');
// const InstanceOperatorServiceArtifact = artifacts.require('services/InstanceOperatorService.sol');

module.exports = async (deployer) => {
  const gif = await Gifcli.connect();

  const productServiceDeployed = await gif.artifact.get('platform', 'development', 'ProductService');
  // const instanceOperatorServiceDeployed =
  // await gif.artifact.get('platform', 'development', 'InstanceOperatorService');
  // const instanceOperatorService = await InstanceOperatorServiceArtifact.at(instanceOperatorServiceDeployed.address)

  if (!process.env.DRYRUN) {
    info(`Deploying FlightDelayEtheriscOracle, ProductService=${productServiceDeployed.address}`);
    const FD = await deployer.deploy(FlightDelayEtheriscOracle, productServiceDeployed.address, { gas: 3500000 });
    const productId = (await FD.productId.call()).toNumber();
    info(`Product deployed; productId = ${productId}`);
    info('Sending artifacts: ');
    // await gif.artifact.send()

    // await instanceOperatorService.approveProduct(productId, { gas: 200000 })
    // .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
  } else {
    info(`Dry Run: productService = ${productServiceDeployed.address}`);
  }
};
