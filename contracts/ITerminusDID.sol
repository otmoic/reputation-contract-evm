// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

interface ITerminusDID {
    struct Metadata {
        string domain;
        string did;
        string notes;
        bool allowSubdomain;
    }

    function ownerOf(uint256 tokenId) external view returns (address);

    function hasTag(string calldata from, string calldata to, string calldata name) external view returns (bool);

    function isRegistered(string calldata domain) external view returns (bool);

    function getTagElem(
        string calldata from,
        string calldata to,
        string calldata name,
        uint256[] calldata elemPath
    ) external view returns (bytes memory);

    function defineTag(
        string calldata domain,
        string calldata name,
        bytes calldata abiType,
        string[][] calldata fieldNames
    ) external;

    function addTag(string calldata from, string calldata to, string calldata name, bytes calldata value) external;

    function pushTagElem(
        string calldata from,
        string calldata to,
        string calldata name,
        uint256[] calldata elemPath,
        bytes calldata value
    ) external;

    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    function register(address tokenOwner, Metadata calldata metadata) external returns (uint256 tokenId);

    function setTagger(string calldata domain, string calldata name, address tagger) external;

    function getDefinedTagNames(string calldata domain) external view returns (string[] memory);
}
