require('ts-node').register({
  files: true,
});
const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config();


module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  plugins: [
    'truffle-contract-size',
    'truffle-plugin-verify'
  ],
  networks: {
    test: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    bsctestnet: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.BSCTEST_RPC),
      network_id: 97,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 6000000,
      gasPrice: 10000000000
    },
    bsc: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.BSC_RPC),
      network_id: 56,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 6000000,
      gasPrice: 5000000000
    },
    mumbai: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.MUMBAI_RPC),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 6000000,
      gasPrice: 10000000000
    },
    polymatic: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.MATIC_RPC),
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 6000000,
      gasPrice: 40000000000
    },
    mainnet: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.MAINNET_RPC),
      network_id: 1,
      confirmations: 3,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    goerli: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.GOERLI_RPC),
      network_id: 5,
      gas: 8000000,
      confirmations: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    rinkeby: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.RINKEBY_RPC),
      network_id: 4,
      gas: 8000000,
      confirmations: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },
  mocha: {
    reporter: "mocha-truffle-reporter"
  },
  compilers: {
    solc: {
      version: "0.8.12"
    }
  },
  api_keys: {
    etherscan: process.env.ETHERSCAN_API,
    polygonscan: process.env.POLYGONSCAN_API,
    bscscan: process.env.BSC_SCAN_API_KEY
  }
};
