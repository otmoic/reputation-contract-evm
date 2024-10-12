require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const PRIV_KEY = process.env.PRIVATE_KEY;
const OP_API_KEY = process.env.OP_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.24",
        settings: {
            viaIR: true,
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        hardhat: {
            forking: {
                url: "https://mainnet.optimism.io",
            },
        },
        op_sepolia: {
            url: "https://sepolia.optimism.io",
            accounts: [PRIV_KEY],
        },
        op: {
            url: `https://mainnet.optimism.io`,
            accounts: [PRIV_KEY],
        },
    },
    etherscan: {
        apiKey: {
            op: OP_API_KEY,
            op_sepolia: OP_API_KEY,
            optimisticEthereum: OP_API_KEY,
        },
        customChains: [
            {
                network: "op_sepolia",
                chainId: 11155420,
                urls: {
                    apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
                    browserURL: "https://sepolia-optimistic.etherscan.io",
                },
            },
        ],
    },
    addresses: {
        op: {
            terminusDIDProxy: "0x5DA4Fa8E567d86e52Ef8Da860de1be8f54cae97D",
            terminusDIDOperator: "0x71D9E0ec99aF672dA13d2D181f984dEAa1E245F1",
            reputation: "0xE924F7f68D1dcd004720e107F62c6303aF271ed3",
        },
    },
};
