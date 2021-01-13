const { info } = require('../io/logger');
const Gifcli = require('@etherisc/gifcli');

const FlightDelayEtheriscOracle = artifacts.require('FlightDelayEtheriscOracle.sol');
const InstanceOperatorServiceArtifact = artifacts.require('services/InstanceOperatorService.sol');


module.exports = async (deployer) => {

  const gif = await Gifcli.connect();
  const productId = 1; // todo: Find out how we can determine this automatically.

  const productServiceDeployed = await gif.artifact.get('platform', 'development', 'ProductService');
  const instanceOperatorServiceDeployed = await gif.artifact.get('platform', 'development', 'InstanceOperatorService');
  const instanceOperatorService = await InstanceOperatorServiceArtifact.at(instanceOperatorServiceDeployed.address)

  if (!process.env.DRYRUN) {
    info(`Deploying FlightDelayEtheriscOracle, ProductService=${productServiceDeployed.address}`);
    await deployer.deploy(FlightDelayEtheriscOracle, productServiceDeployed.address, { gas: 3500000 });
    info('Approve product');
    await instanceOperatorService.approveProduct(productId, { gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
  } else {
    info(`Dry Run: productService = ${productServiceDeployed.address}`);
  }

};
