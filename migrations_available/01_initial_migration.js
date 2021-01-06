
const contractName = 'Migrations';

const contractArtifact = artifacts.require(contractName);

module.exports = function(deployer) {
  deployer.deploy(contractArtifact);
};
