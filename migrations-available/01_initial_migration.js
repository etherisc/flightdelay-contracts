const contractName = 'Migrations'

const contractArtifact = artifacts.require(contractName)

module.exports = (deployer) => {
  deployer.deploy(contractArtifact)
}
