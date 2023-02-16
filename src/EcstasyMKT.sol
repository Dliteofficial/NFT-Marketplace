//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "src/AggregatorV3Interface.sol";

import {EcstasyNFT} from "src/EcstasyNFT.sol";
import {NFTAuction} from "src/NFTAuction.sol";

contract EcstasyMKT is NFTAuction, ReentrancyGuard, Ownable {
 
   EcstasyNFT public nativeNFT;
   AggregatorV3Interface priceFeed;
   
    /* Network: Polygon Mainnet
     * Aggregator: MATIC /USD
     * Addresss: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
     */
    constructor(
        uint _minting_fee, 
        uint _auctionFee, 
        uint _auctionDuration
        ) 
        NFTAuction(
            _auctionFee, 
            _auctionDuration
        ) {
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        nativeNFT = new EcstasyNFT(payable(address(this)));
        _setMintingFee(_minting_fee);
    }

    function _setMintingFee(uint _mintingFee) internal {
        if(_mintingFee < 0.1e18) revert("Invalid Minting Fee");
        minting_fee = _mintingFee;
    }

    receive() external payable{}

    //STARTED FIX HERE..

    function getLatestPrice() public view returns (int) {
    ( , int price, , , ) = priceFeed.latestRoundData();

    return price / 1e8;
    }

    struct listedNFT {
        address NFTAddress;
        address listor;
        uint tokenID;
        uint listingPrice;
        uint timestamp;
    }

    // ILD - Individual Listing Details
    struct ILD {
        uint[] tokenIds;
        uint total;
    }

    uint public listedNFTCount = 1;
    mapping (uint => listedNFT) public listings;
    mapping (address => ILD) public myListings;

    uint public minting_fee; 

    uint listing_fee = 0.1e18;

    function listMyNFTforSale(address _tokenAddress, uint tokenId, uint listingPrice_in_MATIC ) external nonReentrant payable{
        require(msg.value >= listing_fee, "ERR: Minting_fee Error");
        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        listings[listedNFTCount] = listedNFT({
            NFTAddress: _tokenAddress, 
            listor: msg.sender, 
            tokenID: tokenId, 
            listingPrice: listingPrice_in_MATIC,
            timestamp: block.timestamp
            });
        myListings[msg.sender].tokenIds.push(listedNFTCount);
        myListings[msg.sender].total += 1;
        listedNFTCount++;
    }

    function updateListingPrice(uint256 listedTokenID, uint listingPrice_in_MATIC) public payable {
        listedNFT memory listing = listings[listedTokenID];
        require(listing.listor == msg.sender, "ERR: You didn't list it, you cannot update its price");
        require(block.timestamp >= listing.timestamp + 30 days, "ERR: Listing time is less than 30 days");
        listings[listedTokenID].listingPrice = listingPrice_in_MATIC;
    }

    function cancelListing (uint listingId) external {
        require(listings[listingId].listor == msg.sender, "ERR: You didn't the NFT, you cannot cancel");
        listings[listingId].NFTAddress = address(0);
        listings[listingId].listor = address(0);
        listings[listingId].timestamp = 0;
        listings[listingId].listingPrice = 0;
        listings[listingId].tokenID = 0;
    }
    
    function getAllNFTs() public view returns (listedNFT[] memory) {
        listedNFT[] memory returnData = new listedNFT[](listedNFTCount);

        for(uint i; i < listedNFTCount; i++) {
            returnData[i] = listings[i];
        }

        return returnData;
    }

    function numberOfNftsSold() public view returns (uint256) {
        return listedNFTCount;
    }

    function mintEcstasy() external payable {
        require(msg.value >= minting_fee, "ERR: Please pay enough for the Ecstasy NFT");
        nativeNFT.mintEcstasyNFT(msg.sender);
    }

    function buyNFT_Single(uint listingID) external nonReentrant payable{
       listedNFT memory NFTinfo = listings[listingID];
       require(msg.value >= NFTinfo.listingPrice, "ERR: You didn't pay enough for the NFT");
       address tokenAddress = NFTinfo.NFTAddress;
       uint tokenId = NFTinfo.tokenID;
       address listor = NFTinfo.listor;
       //Remove the NFT from myListings. - Moralie
       listings[listingID].NFTAddress = address(0);
       listings[listingID].listor = address(0);
       listings[listingID].timestamp = 0;
       listings[listingID].listingPrice = 0;
       listings[listingID].tokenID = 0;
       IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
       payable(listor).transfer(msg.value);
    }
}
