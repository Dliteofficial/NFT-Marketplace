// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address public owner;

    constructor(string, _name, string _symbol) ERC721(_name, _symbol) {
    owner = msg.sender;
    }
    
modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function holders(address to, string memory tokenURI) public onlyOwner{
        uint newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _tokenIds.increment();
    }
    
}
