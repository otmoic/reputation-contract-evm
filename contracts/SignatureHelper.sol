// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract SignatureHelper {

    struct Bid {
        bytes32 id;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 constant BID_TYPEHASH =
        keccak256("Bid(bytes32 id)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR =
            keccak256(abi.encode(EIP712DOMAIN_TYPEHASH, keccak256("Otmoic Reputation"), keccak256("1"), getChainId(), address(this)));
    }

    function recoverSigner(Bid memory _bid, bytes calldata _sig)
        internal
        view
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sig);
        return ECDSA.recover(getSigningMessage(_bid), v, r, s);
    }

    function getSigningMessage(Bid memory _bid) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BID_TYPEHASH,
                        _bid.id
                )))
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
