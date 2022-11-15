// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721LazyMint.sol";
import "@thirdweb-dev/contracts/extension/DelayedReveal.sol";

/// This is just an EXAMPLE contract that uses `DelayedReveal`.

contract MyContract is ERC721LazyMint, DelayedReveal {
    using TWStrings for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721LazyMint(_name, _symbol, _royaltyRecipient, _royaltyBps) {}

    /**
     *  We override the `lazyMint` function, and use the `_data` paramter for storing encrypted metadata
     *  for 'delayed reveal' NFTs.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public override returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(
                _data,
                (bytes, bytes32)
            );
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint + _amount, _data);
            }
        }

        return super.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /**
     *  We override `tokenURI` to return an appropriate URI for NFTs whose true metadata is encrypted.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        (uint256 batchId, ) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    /**
     *  We only let the owner of the contract reveal the metadata for a batch of NFTs.
     */
    function reveal(uint256 _index, bytes calldata _key)
        external
        override
        returns (string memory revealedURI)
    {
        require(msg.sender == owner(), "Not authorized");

        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);
    }
}