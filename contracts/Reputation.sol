// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ITerminusDID } from "./ITerminusDID.sol";
import { SignatureHelper } from "./SignatureHelper.sol";

contract Reputation is SignatureHelper, UUPSUpgradeable, Ownable2StepUpgradeable {
    ITerminusDID public terminusDID;
    string public tagTypeDomain;
    string public tagName;

    event SubmitComplaint(bytes32 bidId, Complaint complaint, string complainant);

    error DuplicateBidId(bytes32 bidId);
    error InvalidSigner(address signer, address owner);
    error ComplaintTagNoExists();
    error DomainNoExists();

    mapping(bytes32 bidId => bool exists) private submittedBidId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _terminusDID,
        string memory _tagTypeDomain,
        string memory _tagName
    ) external initializer {
        terminusDID = ITerminusDID(_terminusDID);
        tagTypeDomain = _tagTypeDomain;
        tagName = _tagName;

        __signatureHelper_init_init_unchained();
        __Ownable_init_unchained(_msgSender());
    }

    function submitComplaint(Complaint calldata _complaint, bytes calldata _sig, string calldata _domain) external {
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
            terminusDID.pushTagElem(tagTypeDomain, tagTypeDomain, tagName, elemPath, abi.encode(id));
        } else {
            // add array
            bytes32[] memory complaints = new bytes32[](1);
            complaints[0] = id;
            terminusDID.addTag(tagTypeDomain, tagTypeDomain, tagName, abi.encode(complaints));
        }

        emit SubmitComplaint(id, _complaint, _domain);
    }

    function hasComplaint(bytes32 _bidId) external view returns (bool) {
        return submittedBidId[_bidId];
    }

    function concatenatePart1(Complaint calldata _complaint) internal pure returns (string memory) {
        return
            string.concat(
                Strings.toString(_complaint.agreementReachedTime),
                Strings.toString(_complaint.srcChainId),
                Strings.toString(_complaint.srcAddress),
                _complaint.srcToken,
                Strings.toString(_complaint.dstChainId),
                Strings.toString(_complaint.dstAddress),
                _complaint.dstToken
            );
    }

    function concatenatePart2(Complaint calldata _complaint) internal pure returns (string memory) {
        return
            string.concat(
                _complaint.srcAmount,
                _complaint.dstAmount,
                _complaint.dstNativeAmount,
                _complaint.requestor,
                _complaint.lpId
            );
    }

    function concatenatePart3(Complaint calldata _complaint) internal pure returns (string memory) {
        return
            string.concat(
                Strings.toString(_complaint.expectedSingleStepTime),
                Strings.toString(_complaint.tolerantSingleStepTime),
                Strings.toString(_complaint.earliestRefundTime),
                _complaint.userSign,
                _complaint.lpSign
            );
    }

    function concatenateComplaintData(Complaint calldata _complaint) internal pure returns (string memory) {
        return string.concat(concatenatePart1(_complaint), concatenatePart2(_complaint), concatenatePart3(_complaint));
    }

    function getBidId(Complaint calldata _complaint) public pure returns (bytes32) {
        string memory tmp = concatenateComplaintData(_complaint);
        bytes memory tmpBytes = bytes(tmp);
        bytes32 result;
        assembly ("memory-safe") {
            result := keccak256(add(tmpBytes, 32), mload(tmpBytes))
        }
        return result;
    }

    function _domainTokenId(string calldata _domain) internal pure returns (uint256) {
        return uint256(keccak256(bytes(_domain)));
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {}
}
