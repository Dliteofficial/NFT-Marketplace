// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {EcstasyMKT} from "src/EcstasyMKT.sol";

contract EcstasyNFT is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    EcstasyMKT marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == address(marketplace));
        _;
    }

    constructor(address payable _address) ERC721("EcstasyNFT", "eNFT"){
        marketplace = EcstasyMKT(_address);
    }

    function mintEcstasyNFT (address to) external onlyMarketplace{
        uint newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, ""); //Set this when you are ready for production...
        _tokenIds.increment();
    }
}

