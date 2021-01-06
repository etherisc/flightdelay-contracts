
const { Command } = require('@oclif/command');

const fs = require('fs-jetpack');
const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require("web3");

class BaseCommand extends Command {


    getArtifact (contract) {
        const artifact_path = './build/contracts/' + contract + '.json';
        return fs.read(artifact_path, 'json');
    };

    getContract (contract) {
        var artifact = this.getArtifact(contract);
        return new this.web3.eth.Contract(artifact.abi, artifact.networks['5777'].address);
    };

    initContracts() {

        this.provider = new HDWalletProvider(mnemonic, "http://localhost:7545");
        this.web3 = new Web3(this.provider);
        this.web3_WS = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:7545'));

    }


}



module.exports = BaseCommand;
