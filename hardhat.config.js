require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

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
                url: "https://sepolia.optimism.io",
            }
        },
        op_sepolia: {
            url: "https://sepolia.optimism.io",
            accounts: [PRIV_KEY]
        }
    },
    etherscan: {
        apiKey: {
            op_sepolia: OP_API_KEY
        },
        customChains: [
            {
                network: "op_sepolia",
                chainId: 11155420,
                urls: {
                    apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
                    browserURL: "https://sepolia-optimistic.etherscan.io"
                }
            }
        ]
    }
};
