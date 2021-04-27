require('dotenv').config()
const HDWalletProvider = require('@truffle/hdwallet-provider')
const { settings } = require('./package')
const hdWalletConfig = {
  mnemonic: process.env.MNEMONIC,
  providerOrUrl: process.env.HTTP_PROVIDER,
  pollingInterval: 4000
}

module.exports = {
  migrations_directory: process.env.MIGRATIONS_DIRECTORY || './migrations',
  contracts_build_directory: process.env.CONTRACTS_BUILD_DIRECTORY || './build',

  networks: {

    development: {
      provider: () => new HDWalletProvider(hdWalletConfig),
      host: 'wss://xdai.poanetwork.dev',
      port: 443,
      network_id: 100,
      gas: process.env.TRUFFLE_GAS,
      gasPrice: process.env.TRUFFLE_GASPRICE,
      websockets: process.env.TRUFFLE_WEBSOCKETS,
      skipDryRun: true
    },

    xdai: {
      provider: () => new HDWalletProvider(hdWalletConfig),
      host: 'wss://xdai-rpc.etherisc.com',
      port: 443,
      network_id: 100,
      gas: 6600000,
      gasPrice: 2000000000,
      websockets: true,
      skipDryRun: true,
      networkCheckTimeout: 999999
    }

  },

  mocha: {
    timeout: 30000,
    useColors: true
  },

  compilers: {
    solc: {
      version: settings.solc,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
        evmVersion: 'petersburg' // -> constantinople
      }
    }
  }
}
