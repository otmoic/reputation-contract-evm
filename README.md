# Reputation Contract

## Intro

The reputation contract is TerminusDID Tagger, which helps Terminus Name `otmoic.reputation` to set `complaints` tag. The tag is defined as Bytes32 array. The reputation contract will append new issued complaint bid id to the tag.

The complaints play an important role at Otmoic ecosystem. We have another system to provide credit points of users and lps. Once there is a complaint to the user/lp and the complaint is verified, the user/lp's point will be deducted permanently from that system.


## Usage

This project is built based on Hardhat, including a contract file, a test script, and a deployment script. As the contract heavily relied on TerminusDID contract, the test is conducted with forked OP sepolia, where the TerminusDID contract was deployed.

### Test
```shell
// test on op sepolia latest block fork
npx hardhat test
```

### Deploy

```
// deployment on op sepolia testnet
npx hardhat run scripts/deploy.js --network op_sepolia
```

```
// verify contract
npx hardhat verify --network op_sepolia <contract_address> <params>
// example
npx hardhat verify --network op_sepolia 0xEf11aAFd7b6ba47A5eBE43F8eCAAac9E441970e7 0x4c8c98e652d6a01494971a8faF5d3b68338f9ED4 otmoic.reputation complaints
```