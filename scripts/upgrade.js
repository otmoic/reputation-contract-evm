const { ethers, network, upgrades } = require("hardhat");
const config = require("../hardhat.config");

async function main() {
    const REPUTATIONS_ADDR = config.addresses[network.name].reputation;

    // upgrades reputation contract
    const Reputation = await ethers.getContractFactory("Reputation");
    const reputation = await upgrades.upgradeProxy(REPUTATIONS_ADDR, Reputation);

    await reputation.waitForDeployment();
    const reputationAddr = await reputation.getAddress();
    console.log("Reputation upgraded to:", reputationAddr);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
