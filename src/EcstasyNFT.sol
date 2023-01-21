// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "src/NFTMarketplace.sol";

contract EcstasyNFT is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    EcstasyMKT marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == address(marketplace));
        _;
    }

    constructor(address _address) ERC721("ECstasyNFT", "eNFT"){
        marketplace = EcstasyMKT(_address);
    }

    function mintEcstasyNFT (address to, string memory tokenURI) external onlyMarketplace{
        uint newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _tokenIds.increment();
    }
}

