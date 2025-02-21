const { ethers, network } = require("hardhat");
const config = require("../hardhat.config");

async function main() {
    const [wallet] = await ethers.getSigners();
    const userBalance = await ethers.provider.getBalance(wallet.address);
    console.log(`Load user wallet: ${wallet.address} -> native token: ${userBalance}`);

    const REPUTATION_ADDR = config.addresses[network.name].reputation;
    const reputation = await ethers.getContractAt("Reputation", REPUTATION_ADDR, wallet);

    let _agreementReachedTime = Math.floor(Date.now() / 1000);
    let _expectedSingleStepTime = 60;
    let _tolerantSingleStepTime = 60;
    let _earliestRefundTime = _agreementReachedTime + 3 * _expectedSingleStepTime + 3 * _tolerantSingleStepTime;

    const complaint = {
        srcChainId: 1,
        srcAddress: "0x945e9704D2735b420363071bB935ACf2B9C4b814",
        srcToken: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        dstChainId: 10,
        dstAddress: "0x945e9704D2735b420363071bB935ACf2B9C4b814",
        dstToken: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        srcAmount: "1000",
        dstAmount: "1000",
        dstNativeAmount: "0",
        requestor: "did:requestor",
        lpId: "did:lpId",
        expectedSingleStepTime: _expectedSingleStepTime,
        tolerantSingleStepTime: _tolerantSingleStepTime,
        earliestRefundTime: _earliestRefundTime,
        agreementReachedTime: _agreementReachedTime,
        userSign: "userSign",
        lpSign: "lpSign",
    };

    const chaind = await ethers.provider.getNetwork();
    const eip712Domain = {
        name: "Otmoic Reputation",
        version: "1",
        chainId: chaind.chainId,
        verifyingContract: REPUTATION_ADDR,
    };

    const complaintType = {
        Complaint: [
            { name: "srcChainId", type: "uint64" },
            { name: "srcAddress", type: "uint256" },
            { name: "srcToken", type: "string" },
            { name: "dstChainId", type: "uint64" },
            { name: "dstAddress", type: "uint256" },
            { name: "dstToken", type: "string" },
            { name: "srcAmount", type: "string" },
            { name: "dstAmount", type: "string" },
            { name: "dstNativeAmount", type: "string" },
            { name: "requestor", type: "string" },
            { name: "lpId", type: "string" },
            { name: "expectedSingleStepTime", type: "uint64" },
            { name: "tolerantSingleStepTime", type: "uint64" },
            { name: "earliestRefundTime", type: "uint64" },
            { name: "agreementReachedTime", type: "uint64" },
            { name: "userSign", type: "string" },
            { name: "lpSign", type: "string" },
        ],
    };

    let sig = await wallet.signTypedData(eip712Domain, complaintType, complaint);
    let tx;
    let txComfirm;

    // for (let [key, value] of Object.entries(complaint)) {
    //     console.log(`"${key}": "${value}",`);
    // }
    // console.log(complaint, sig, "song.net");

    tx = await reputation.submitComplaint(complaint, sig, "otmoic.reputation");
    txComfirm = await tx.wait();
    console.log(`complaint submitted: ${txComfirm.hash}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
