const { info } = require('../io/logger');

RiskPool = artifacts.require('RiskPool');

module.exports = async (deployer) => {

  info(`Deploying RiskPool`);
  await deployer.deploy(RiskPool, { gas: 3500000 });

};
