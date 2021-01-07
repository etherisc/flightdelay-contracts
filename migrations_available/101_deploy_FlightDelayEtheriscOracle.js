const { info } = require('../io/logger');
const Gifcli = require('@etherisc/gifcli');

const FlightDelayEtheriscOracle = artifacts.require('FlightDelayEtheriscOracle.sol');


module.exports = async (deployer) => {
  const gif = await Gifcli.connect();

  const productService = await gif.getArtifact('platform', 'development', 'ProductService');
  const instanceOperatorService = gif.getArtifact('platform', 'development', 'InstanceOperatorService');
  console.log(`productService=${productService.address}; instanceOperatorService=${instanceOperatorService.address}`);

  await deployer.deploy(FlightDelayEtheriscOracle, productService.address, { gas: 3500000 });
  const productId = 2;

  info('Approve product');
  //await instanceOperator.approveProduct(productId, { gas: 200000 })
  //  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
};
