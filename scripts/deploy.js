const hre = require("hardhat");
require('dotenv').config()

const TERMINUSDID_ADDR = process.env.TERMINUSDID_ADDR;
const ethers = hre.ethers;

async function main() {

    const tagTypeDomain = "otmoic.reputation";
    const tagName = "complaints";
    const [operator] = await ethers.getSigners();
    const operatorAddr = operator.address;
    const terminusDID = await ethers.getContractAt("ITerminusDID", TERMINUSDID_ADDR, operator)


    const hasDomain = await terminusDID.isRegistered(tagTypeDomain);
    if (!hasDomain) {
        // register domain
        const topLevelDomain = tagTypeDomain.split(".")[1];
        const registerTopDomain = terminusDID.interface.encodeFunctionData("register", [operatorAddr, {
            domain: topLevelDomain,
            did: "did",
            notes: "",
            allowSubdomain: true
        }]);
        const registerDomain = terminusDID.interface.encodeFunctionData("register", [operatorAddr, {
            domain: tagTypeDomain,
            did: "did",
            notes: "",
            allowSubdomain: true
        }]);
        await terminusDID.connect(operator).multicall([registerTopDomain, registerDomain]);
        console.log(`register domain done: ${tagTypeDomain}`);

        // deploy reputation contract
        const reputation = await ethers.deployContract("Reputation", [TERMINUSDID_ADDR, tagTypeDomain, tagName]);
        await reputation.waitForDeployment();
        const reputationAddr = await reputation.getAddress();
        console.log(`deployed Reputation contract: ${reputationAddr}`);

        // define tag type
        const bytes32ArrayType = ethers.getBytes("0x040820"); // // bytes32 array
        await terminusDID.defineTag(tagTypeDomain, tagName, bytes32ArrayType, []);
        console.log(`defined tag type bytes32[] on domain ${tagTypeDomain} with name ${tagName}`);

        // specify tagger as reputation contract for tag type
        await terminusDID.setTagger(tagTypeDomain, tagName, reputationAddr);
        console.log(`specify tagger ${reputationAddr} for above tagType`)
    } else {
        console.log(`already register domain: ${tagTypeDomain} and tag ${tagName}`);
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
