// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract SignatureHelper is Initializable {
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
        string requestor;
        string lpId;
        uint64 expectedSingleStepTime;
        uint64 tolerantSingleStepTime;
        uint64 earliestRefundTime;
        uint64 agreementReachedTime;
        string userSign;
        string lpSign;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 constant COMPLAINT_TYPEHASH =
        keccak256(
            "Complaint(uint64 srcChainId,uint256 srcAddress,string srcToken,uint64 dstChainId,uint256 dstAddress,string dstToken,string srcAmount,string dstAmount,string dstNativeAmount,string requestor,string lpId,uint64 expectedSingleStepTime,uint64 tolerantSingleStepTime,uint64 earliestRefundTime,uint64 agreementReachedTime,string userSign,string lpSign)"
        );

    bytes32 public DOMAIN_SEPARATOR;

    function __signatureHelper_init() internal onlyInitializing {
        __signatureHelper_init_init_unchained();
    }

    function __signatureHelper_init_init_unchained() internal onlyInitializing {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("Otmoic Reputation"),
                keccak256("1"),
                getChainId(),
                address(this)
            )
        );
    }

    function recoverSigner(Complaint memory _complaint, bytes calldata _sig) internal view returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sig);
        return ECDSA.recover(getSigningMessage(_complaint), v, r, s);
    }

    function getSigningMessage(Complaint memory _complaint) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        bytes.concat(
                            abi.encode(
                                COMPLAINT_TYPEHASH,
                                _complaint.srcChainId,
                                _complaint.srcAddress,
                                keccak256(bytes(_complaint.srcToken)),
                                _complaint.dstChainId,
                                _complaint.dstAddress,
                                keccak256(bytes(_complaint.dstToken))
                            ),
                            abi.encode(
                                keccak256(bytes(_complaint.srcAmount)),
                                keccak256(bytes(_complaint.dstAmount)),
                                keccak256(bytes(_complaint.dstNativeAmount)),
                                keccak256(bytes(_complaint.requestor)),
                                keccak256(bytes(_complaint.lpId))
                            ),
                            abi.encode(
                                _complaint.expectedSingleStepTime,
                                _complaint.tolerantSingleStepTime,
                                _complaint.earliestRefundTime,
                                _complaint.agreementReachedTime,
                                keccak256(bytes(_complaint.userSign)),
                                keccak256(bytes(_complaint.lpSign))
                            )
                        )
                    )
                )
            );
    }

    function splitSignature(bytes memory _sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    /**
     * @notice Returns the current chainId using the chainid opcode
     * @return id uint256 The chain id
     */
    function getChainId() internal view returns (uint256 id) {
        // no-inline-assembly
        assembly {
            id := chainid()
        }
    }
}
