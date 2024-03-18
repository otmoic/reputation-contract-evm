// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ITerminusDID} from "./ITerminusDID.sol";
import {SignatureHelper} from "./SignatureHelper.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Reputation is SignatureHelper {
    ITerminusDID public terminusDID;
    string public tagTypeDomain;
    string public tagName;

    event SubmitComplaint(bytes32 bidId, Complaint complaint);

    error DuplicateBidId(bytes32 bidId);
    error InvalidSigner(address signer, address owner);
    error ComplaintTagNoExists();
    error DomainNoExists();

    mapping(bytes32 bidId => bool exists) private submittedBidId;

    constructor(
        address _terminusDID,
        string memory _tagTypeDomain,
        string memory _tagName
    ) {
        terminusDID = ITerminusDID(_terminusDID);
        tagTypeDomain = _tagTypeDomain;
        tagName = _tagName;
    }

    function submitComplaint(
        Complaint calldata _complaint,
        bytes calldata _sig,
        string calldata _domain
    ) external {
        bytes32 id = getBidId(_complaint);

        // check bid id has submitted or not
        if (submittedBidId[id]) {
            revert DuplicateBidId(id);
        }
        submittedBidId[id] = true;

        // verify complaint data and signature address
        if (!terminusDID.isRegistered(_domain)) {
            revert DomainNoExists();
        }
        address signer = recoverSigner(_complaint, _sig);
        address domainOwner = terminusDID.ownerOf(_domainTokenId(_domain));
        if (signer != domainOwner) {
            revert InvalidSigner(signer, domainOwner);
        }

        // add complaint to DID registry
        bool hasTag = terminusDID.hasTag(tagTypeDomain, tagTypeDomain, tagName);
        if (hasTag) {
            // push to array
            uint256[] memory elemPath;
            terminusDID.pushTagElem(
                tagTypeDomain,
                tagTypeDomain,
                tagName,
                elemPath,
                abi.encode(id)
            );
        } else {
            // add array
            bytes32[] memory complaints = new bytes32[](1);
            complaints[0] = id;
            terminusDID.addTag(
                tagTypeDomain,
                tagTypeDomain,
                tagName,
                abi.encode(complaints)
            );
        }

        emit SubmitComplaint(id, _complaint);
    }

    function hasComplaint(bytes32 _bidId) external view returns (bool) {
        return submittedBidId[_bidId];
    }

    function getBidId(
        Complaint calldata _complaint
    ) public pure returns (bytes32) {
        string memory tmp = Strings.toString(_complaint.agreementReachedTime);
        tmp = string.concat(
            tmp,
            Strings.toString(_complaint.srcChainId),
            Strings.toString(_complaint.srcAddress),
            _complaint.srcToken,
            Strings.toString(_complaint.dstChainId),
            Strings.toString(_complaint.dstAddress),
            _complaint.dstToken
        );
        tmp = string.concat(
            tmp,
            _complaint.srcAmount,
            _complaint.dstAmount,
            _complaint.dstNativeAmount
        );
        tmp = string.concat(
            tmp,
            _complaint.requestor,
            _complaint.lpId,
            Strings.toString(_complaint.stepTimeLock),
            _complaint.userSign,
            _complaint.lpSign
        );
        return keccak256(bytes(tmp));
    }

    function _domainTokenId(
        string calldata _domain
    ) internal pure returns (uint256) {
        return uint256(keccak256(bytes(_domain)));
    }
}
