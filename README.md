# reputation-contract-evm

```shell
// test on op sepolia latest block fork
npx hardhat test

// deployment on op sepolia testnet
npx hardhat run scripts/deploy.js --network op_sepolia

// verify contract
npx hardhat verify --network op_sepolia <contract_address> <params>
// example
npx hardhat verify --network op_sepolia 0xEf11aAFd7b6ba47A5eBE43F8eCAAac9E441970e7 0x4c8c98e652d6a01494971a8faF5d3b68338f9ED4 otmoic.reputation complaints
```
