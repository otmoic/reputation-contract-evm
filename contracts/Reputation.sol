// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ITerminusDID} from "./ITerminusDID.sol";
import {SignatureHelper} from "./SignatureHelper.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Reputation is SignatureHelper {
    ITerminusDID public terminusDID;
    string public tagTypeDomain;
    string public tagName;

    event SubmitComplaint(bytes32 bidId);
    
    error InvalidSigner(address signer, address owner);
    error ComplaintTagNoExists();
    error DomainNoExists();

    struct Complaint {
        uint64 srcChainId;
        uint256 srcAddress;
        string srcToken;
        uint64 dstChainId;
        uint256 dstAddress;
        string dstToken;
        string srcAmount;
        string dstAmount;
        string dstNativeAmount;
        string lpId;
        uint64 stepTimeLock;
        uint64 agreementReachedTime;
        string userSign;
        string lpSign;
    }

    constructor(address _terminusDID, string memory _tagTypeDomain, string memory _tagName) {
        terminusDID = ITerminusDID(_terminusDID);
        tagTypeDomain = _tagTypeDomain;
        tagName = _tagName;
    }

    function submitComplaint(Complaint calldata _complaint, bytes calldata _sig, string calldata _domain) external {
        // verify complaint data and signature address
        bytes32 id = getBidId(_complaint);
        address signer = recoverSigner(Bid(id), _sig);
        bool exists = terminusDID.isRegistered(_domain);
        if (!exists) {
            revert DomainNoExists();
        }
        address domainOwner = terminusDID.ownerOf(_domainTokenId(_domain));
        if (signer != domainOwner) {
            revert InvalidSigner(signer, domainOwner);
        }

        // add complaint to DID registry
        bool hasTag = terminusDID.hasTag(tagTypeDomain, tagTypeDomain, tagName);
        if (hasTag) {
            // push to array
            uint256[] memory elemPath;
            terminusDID.pushTagElem(tagTypeDomain, tagTypeDomain, tagName, elemPath, abi.encode(id));
        } else {
            // add array
            bytes32[] memory complaints = new bytes32[](1);
            complaints[0] = id;
            terminusDID.addTag(tagTypeDomain, tagTypeDomain, tagName, abi.encode(complaints));
        }

        emit SubmitComplaint(id);
    }

    function hasComplaint(bytes32 _bidId) external view returns (bool) {
        if (!terminusDID.hasTag(tagTypeDomain, tagTypeDomain, tagName)) {
            revert ComplaintTagNoExists();
        }
        uint256[] memory elemPath;
        bytes memory gotData = terminusDID.getTagElem(tagTypeDomain, tagTypeDomain, tagName, elemPath);
        bytes32[] memory bidIds = abi.decode(gotData, (bytes32[]));
        for (uint256 i = 0; i < bidIds.length; ++i) {
            if (_bidId == bidIds[i]) {
                return true;
            }
        }
        return false;
    }

    function getBidId(Complaint calldata _complaint) public pure returns (bytes32) {
        string memory tmp = Strings.toString(_complaint.srcChainId);
        tmp = string.concat(tmp, Strings.toString(_complaint.srcAddress));
        tmp = string.concat(tmp, _complaint.srcToken);
        tmp = string.concat(tmp, Strings.toString(_complaint.dstChainId));
        tmp = string.concat(tmp, Strings.toString(_complaint.dstAddress));
        tmp = string.concat(tmp, _complaint.dstToken);
        tmp = string.concat(tmp, _complaint.srcAmount);
        tmp = string.concat(tmp, _complaint.dstAmount);
        tmp = string.concat(tmp, _complaint.dstNativeAmount);
        tmp = string.concat(tmp, _complaint.lpId);
        tmp = string.concat(tmp, Strings.toString(_complaint.stepTimeLock));
        tmp = string.concat(tmp, Strings.toString(_complaint.agreementReachedTime));
        tmp = string.concat(tmp, _complaint.userSign);
        tmp = string.concat(tmp, _complaint.lpSign);
        return keccak256(bytes(tmp));
    }

    function _domainTokenId(string calldata _domain) internal pure returns (uint256) {
        return uint256(keccak256(bytes(_domain)));
    }
}
