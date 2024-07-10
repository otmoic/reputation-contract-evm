const { ethers, upgrades } = require('hardhat');
const {
    time,
    loadFixture,
    impersonateAccount,
    setBalance,
} = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { expect } = require('chai');
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');

const config = require('../hardhat.config');

describe('Reputation', function () {
    async function setep() {
        // make test data
        const complaint = {
            srcChainId: 1,
            srcAddress: '0x945e9704D2735b420363071bB935ACf2B9C4b814',
            srcToken: '0xdac17f958d2ee523a2206206994597c13d831ec7',
            dstChainId: 10,
            dstAddress: '0x945e9704D2735b420363071bB935ACf2B9C4b814',
            dstToken: '0xdac17f958d2ee523a2206206994597c13d831ec7',
            srcAmount: '1000',
            dstAmount: '1000',
            dstNativeAmount: '0',
            requestor: 'did:requestor',
            lpId: 'did:lpId',
            stepTimeLock: 60,
            agreementReachedTime: await time.latest(),
            userSign: 'userSign',
            lpSign: 'lpSign',
        };

        const [owner] = await ethers.getSigners();
        const network = await await ethers.provider.getNetwork();

        // deploy reputation contract
        const Reputation = await ethers.getContractFactory('Reputation');
        const terminusDIDAddr = config.addresses['op'].terminusDIDProxy;
        const tagTypeDomain = 'otmoicT.reputationT';
        const tagName = 'complaints';

        const reputation = await upgrades.deployProxy(Reputation, [terminusDIDAddr, tagTypeDomain, tagName], {
            initializer: 'initialize',
            kind: 'uups',
            constructorArgs: [],
        });

        const reputationAddr = await reputation.getAddress();

        // eip712 signature domain type
        const eip712Domain = {
            name: 'Otmoic Reputation',
            version: '1',
            chainId: network.chainId,
            verifyingContract: reputationAddr,
        };

        // eip712 signature message type
        const complaintType = {
            Complaint: [
                { name: 'srcChainId', type: 'uint64' },
                { name: 'srcAddress', type: 'uint256' },
                { name: 'srcToken', type: 'string' },
                { name: 'dstChainId', type: 'uint64' },
                { name: 'dstAddress', type: 'uint256' },
                { name: 'dstToken', type: 'string' },
                { name: 'srcAmount', type: 'string' },
                { name: 'dstAmount', type: 'string' },
                { name: 'dstNativeAmount', type: 'string' },
                { name: 'requestor', type: 'string' },
                { name: 'lpId', type: 'string' },
                { name: 'stepTimeLock', type: 'uint64' },
                { name: 'agreementReachedTime', type: 'uint64' },
                { name: 'userSign', type: 'string' },
                { name: 'lpSign', type: 'string' },
            ],
        };

        // impersonate terminussDID's operator
        const operatorAddr = config.addresses['op'].terminusDIDOperator;
        await impersonateAccount(operatorAddr);
        const operator = await ethers.getSigner(operatorAddr);
        let operatorBal = await operator.provider.getBalance(operator.address);

        if (operatorBal < ethers.parseEther('1')) {
            await setBalance(operator.address, ethers.parseEther('1'));
        }

        // console.log(operator.address, await operator.provider.getBalance(operator.address));

        // get terminusDID contract
        const terminusDID = await ethers.getContractAt('ITerminusDID', terminusDIDAddr, operator);

        // if tagTypeand tag is not ready on terminusDID contract, then make it
        const hasDomain = await terminusDID.isRegistered(tagTypeDomain);
        // console.log('hasDomain', hasDomain);
        if (!hasDomain) {
            // register domain
            const topLevelDomain = tagTypeDomain.split('.')[1];
            const registerTopDomain = terminusDID.interface.encodeFunctionData('register', [
                operatorAddr,
                {
                    domain: topLevelDomain,
                    did: 'did',
                    notes: 'local fork test for Reputation contract',
                    allowSubdomain: true,
                },
            ]);
            const registerDomain = terminusDID.interface.encodeFunctionData('register', [
                operatorAddr,
                {
                    domain: tagTypeDomain,
                    did: 'did',
                    notes: 'local fork test for Reputation contract',
                    allowSubdomain: true,
                },
            ]);
            await terminusDID.connect(operator).multicall([registerTopDomain, registerDomain]);
            console.log(`register domain done: ${tagTypeDomain}`);

            // define tag type
            const bytes32ArrayType = ethers.getBytes('0x040820'); // // bytes32 array
            await terminusDID.defineTag(tagTypeDomain, tagName, bytes32ArrayType, []);
            console.log(`defined tag type bytes32[] on domain ${tagTypeDomain} with name ${tagName}`);

            // specify tagger as reputation contract for tag type
            await terminusDID.setTagger(tagTypeDomain, tagName, reputationAddr);
            console.log(`specify tagger ${reputationAddr} for above tagType`);
        } else {
            console.log(`already register domain: ${tagTypeDomain} and tag ${tagName}`);
        }

        return {
            reputation,
            terminusDIDAddr,
            terminusDID,
            tagTypeDomain,
            tagName,
            owner,
            complaint,
            eip712Domain,
            complaintType,
        };
    }

    describe('basis check', function () {
        it('should set the right terminusDIDAddr and tagTypeDomain', async function () {
            const { reputation, terminusDIDAddr, tagTypeDomain, tagName } = await loadFixture(setep);
            expect(await reputation.terminusDID()).to.equal(terminusDIDAddr);
            expect(await reputation.tagTypeDomain()).to.equal(tagTypeDomain);
            expect(await reputation.tagName()).to.equal(tagName);
        });
    });

    describe('bid id check', function () {
        it('bid id offchain and onchain should be the same', async function () {
            const { reputation, complaint } = await loadFixture(setep);
            let bidIdOrigin = makeBidIdOrigin(complaint);
            let bidId = makeBidId(bidIdOrigin);
            let bidIdOnChain = await reputation.getBidId(complaint);
            expect(bidId).to.equal(bidIdOnChain);
        });
    });

    describe('signature check', function () {
        it('sign bid with my address', async function () {
            const { reputation, complaint, eip712Domain, complaintType, owner, terminusDID } = await loadFixture(setep);
            let bidId = makeBidId(makeBidIdOrigin(complaint));
            let sig = await owner.signTypedData(eip712Domain, complaintType, complaint);

            // to be a qualified address to submit complaint, the address should own a domain
            await terminusDID.register(owner.address, {
                domain: 'reputationTestUser',
                did: 'did',
                notes: 'local fork test for Reputation contract',
                allowSubdomain: true,
            });

            await expect(reputation.submitComplaint(complaint, sig, 'reputationTestUser'))
                .to.emit(reputation, 'SubmitComplaint')
                .withArgs(bidId, anyValue, 'reputationTestUser');

            let exists = await reputation.hasComplaint(bidId);
            expect(exists).to.be.true;
        });

        it('avoid replay attack', async function () {
            const { reputation, complaint, eip712Domain, complaintType, owner, terminusDID } = await loadFixture(setep);
            let bidId = makeBidId(makeBidIdOrigin(complaint));
            let sig = await owner.signTypedData(eip712Domain, complaintType, complaint);

            // to be a qualified address to submit complaint, the address should own a domain
            await terminusDID.register(owner.address, {
                domain: 'reputationTestUser',
                did: 'did',
                notes: 'local fork test for Reputation contract',
                allowSubdomain: true,
            });

            await reputation.submitComplaint(complaint, sig, 'reputationTestUser');
            await expect(reputation.submitComplaint(complaint, sig, 'reputationTestUser'))
                .to.be.revertedWithCustomError(reputation, 'DuplicateBidId')
                .withArgs(bidId);
        });

        it('sign bid with address outside terminus domain', async function () {
            const { reputation, complaint, eip712Domain, complaintType, owner } = await loadFixture(setep);
            let sig = await owner.signTypedData(eip712Domain, complaintType, complaint);

            await expect(reputation.submitComplaint(complaint, sig, 'song.com'))
                .to.be.revertedWithCustomError(reputation, 'InvalidSigner')
                .withArgs(owner.address, '0x40688b08ef03a5250706f6E120cb24Dfb5601B70');

            await expect(
                reputation.submitComplaint(complaint, sig, 'reputationTestUser'),
            ).to.be.revertedWithCustomError(reputation, 'DomainNoExists');
        });
    });
});

function makeBidIdOrigin(complaint) {
    return (
        complaint.agreementReachedTime.toString() +
        complaint.srcChainId.toString() +
        ethers.toBigInt(complaint.srcAddress).toString() +
        complaint.srcToken +
        complaint.dstChainId.toString() +
        ethers.toBigInt(complaint.dstAddress).toString() +
        complaint.dstToken +
        complaint.srcAmount +
        complaint.dstAmount +
        complaint.dstNativeAmount +
        complaint.requestor +
        complaint.lpId +
        complaint.stepTimeLock.toString() +
        complaint.userSign +
        complaint.lpSign
    );
}

function makeBidId(bidIdOrigin) {
    return ethers.keccak256(ethers.toUtf8Bytes(bidIdOrigin));
}
