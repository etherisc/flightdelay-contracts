const { info } = require('../io/logger');


const FlightDelayEtheriscOracle = artifacts.require('FlightDelayEtheriscOracle.sol');
const ProductService = artifacts.require('services/ProductService.sol');
const InstanceOperatorService = artifacts.require('services/InstanceOperatorService.sol');


module.exports = async (deployer) => {
  const productService = await ProductService.deployed();
  const instanceOperator = await InstanceOperatorService.deployed();

  await deployer.deploy(FlightDelayEtheriscOracle, productService.address, { gas: 3500000 });
  const productId = 2;

  info('Approve product');
  await instanceOperator.approveProduct(productId, { gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
};
