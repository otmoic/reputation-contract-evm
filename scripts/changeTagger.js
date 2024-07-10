const { ethers, network, upgrades } = require('hardhat');
const config = require('../hardhat.config');

async function main() {
    const tagTypeDomain = 'otmoic.reputation';
    const tagName = 'complaints';
    const [operator] = await ethers.getSigners();

    const TERMINUSDID_ADDR = config.addresses[network.name].terminusDIDProxy;
    const terminusDID = await ethers.getContractAt('ITerminusDID', TERMINUSDID_ADDR, operator);

    const hasDomain = await terminusDID.isRegistered(tagTypeDomain);
    if (!hasDomain) {
        return console.log(`tag type domain ${tagTypeDomain} has not registered yet`);
    }

    const tags = await terminusDID.getDefinedTagNames(tagTypeDomain);
    const gotTag = tags[0];

    if (gotTag !== tagName) {
        return console.log(`tag name ${tagName} has not defined yet`);
    }

    // deploy reputation contract
    const Reputation = await ethers.getContractFactory('Reputation');
    const reputation = await upgrades.deployProxy(Reputation, [TERMINUSDID_ADDR, tagTypeDomain, tagName], {
        initializer: 'initialize',
        kind: 'uups',
        constructorArgs: [],
    });

    await reputation.waitForDeployment();
    const reputationAddr = await reputation.getAddress();
    console.log(`deployed Reputation contract: ${reputationAddr}`);

    // specify tagger as reputation contract for tag type
    await terminusDID.setTagger(tagTypeDomain, tagName, reputationAddr);
    console.log(`specify tagger ${reputationAddr} for above tagType`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
