//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {EcstasyNFT} from "src/EcstasyNFT.sol";
import {NFTAuction} from "src/NFTAuction.sol";

contract EcstasyMKT is NFTAuction, ReentrancyGuard, Ownable {
 
   EcstasyNFT public immutable nativeNFT;
   uint public listedNFTCount = 1;
   mapping (uint => listedNFT) public listings;
   mapping (address => ILD) public myListings;
   uint public minting_fee;
   uint public listing_fee;

   error ZeroAddress();
   error InvalidMintingFee();
   error InvalidListingFee();
   error IncorrectAmountPaid();
   error NFTSoldOrCanceled();
   error IncorrectMSG_SENDER();
   error TimestampError();

    struct listedNFT { //Revisit, Possible gas reduction
        address NFTAddress;
        address listor;
        uint tokenID;
        uint listingPrice;
        uint timestamp;
        bool canceled_sold;
    }

    // ILD - Individual Listing Details
    struct ILD {
        uint[] tokenIds;
        uint total;
    }

    event listingSuccessful (address tokenAddress, uint tokenId, uint listingPrice);
    event listingPriceUpdated (uint listingId, uint listingPrice);
    event listingCanceled(uint listingId);
    event mintSuccessful(address owner, uint tokenId);
    event NFTBought(address buyer, uint listingID, address tokenAddress, uint tokenId, uint bargainPrice);
    event mintingFeeSet(uint newMintingFee);
    event listingFeeSet(uint newListingFee);

    constructor(
        uint _minting_fee, 
        uint _auctionFee, 
        uint _auctionDuration,
        uint _listing_fee
        ) 
        NFTAuction(
            _auctionFee, 
            _auctionDuration,
            msg.sender
        ) {
        nativeNFT = new EcstasyNFT(payable(address(this)));
        _setMintingFee(_minting_fee);
        _setListingFee(_listing_fee);
    }

    receive() external payable{}

    ///////////////////////////////////////////////////////
    ////////////////  EXTERNAL FUNCTIONS     /////////////
    //////////////////////////////////////////////////////

    function listMyNFTforSale(address _tokenAddress, uint tokenId, uint listingPrice_in_MATIC ) external nonReentrant payable{
        if(msg.value < listing_fee) revert InvalidListingFee();
        if(_tokenAddress == address(0)) revert ZeroAddress();
        IERC721(_tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        listings[listedNFTCount] = listedNFT({
            NFTAddress: _tokenAddress, 
            listor: msg.sender, 
            tokenID: tokenId, 
            listingPrice: listingPrice_in_MATIC,
            timestamp: block.timestamp,
            canceled_sold: false
            });
        myListings[msg.sender].tokenIds.push(listedNFTCount);
        myListings[msg.sender].total += 1;
        listedNFTCount++;

        emit listingSuccessful(_tokenAddress, tokenId, listingPrice_in_MATIC);
    }

    function updateListingPrice(uint256 listedTokenID, uint listingPrice_in_MATIC) external payable {
        listedNFT memory listing = listings[listedTokenID];
        if(msg.sender != listing.listor) revert IncorrectMSG_SENDER();
        if(block.timestamp < listing.timestamp + 30 days) revert TimestampError();
        listings[listedTokenID].listingPrice = listingPrice_in_MATIC;

        emit listingPriceUpdated(listedTokenID, listingPrice_in_MATIC);
    }

    function cancelListing (uint listingId) external {
        listedNFT memory NFTinfo = listings[listingId];
        if(msg.sender != NFTinfo.listor) revert IncorrectMSG_SENDER();
        if(NFTinfo.canceled_sold == true) revert NFTSoldOrCanceled();
        address nftAddr = NFTinfo.NFTAddress;
        uint tokenId = NFTinfo.tokenID;
        NFTinfo.NFTAddress = address(0);
        NFTinfo.listor = address(0);
        NFTinfo.timestamp = 0;
        NFTinfo.listingPrice = 0;
        NFTinfo.tokenID = 0;
        NFTinfo.canceled_sold = true;
        listings[listingId] = NFTinfo;
        IERC721(nftAddr).transferFrom(address(this), msg.sender, tokenId);

        emit listingCanceled(listingId);
    }

    function mintEcstasy() external payable {
        if(msg.value < minting_fee) revert InvalidMintingFee();
        nativeNFT.mintEcstasyNFT(msg.sender);
        
        emit mintSuccessful(msg.sender, nativeNFT._tokenIds() - 1);
    }
    
    function buyNFT(uint listingID) external nonReentrant payable{
       listedNFT memory NFTinfo = listings[listingID];
       if(msg.value < NFTinfo.listingPrice) revert IncorrectAmountPaid();
       if(NFTinfo.canceled_sold == true) revert NFTSoldOrCanceled();
       address tokenAddress = NFTinfo.NFTAddress;
       uint tokenId = NFTinfo.tokenID;
       address listor = NFTinfo.listor;
       NFTinfo.NFTAddress = address(0);
       NFTinfo.listor = address(0);
       NFTinfo.timestamp = 0;
       NFTinfo.listingPrice = 0;
       NFTinfo.tokenID = 0;
       NFTinfo.canceled_sold = true;
       listings[listingID] = NFTinfo;
       IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
       payable(listor).transfer(msg.value);

       emit NFTBought(msg.sender, listingID, tokenAddress, tokenId, msg.value);
    }

    ///////////////////////////////////////////////////////
    ////////////////  VIEW FUNCTIONS     /////////////////
    //////////////////////////////////////////////////////

    function getAllNFTs() external view returns (listedNFT[] memory) {
        listedNFT[] memory returnData = new listedNFT[](listedNFTCount);

        for(uint i; i < listedNFTCount; ++i) {
            returnData[i] = listings[i];
        }

        return returnData;
    }

    function numberOfNftsListed() external view returns (uint256) {
        return listedNFTCount - 1; //since listedNFT Count started from one, we need to reduce by 1
    }

    ///////////////////////////////////////////////////////
    ////////////////  INTERNAL FUNCTIONS     /////////////
    //////////////////////////////////////////////////////

    function _setMintingFee(uint _mintingFee) internal {
        if(_mintingFee < 0.1e18) revert InvalidMintingFee();
        minting_fee = _mintingFee;

        emit mintingFeeSet(_mintingFee);
    }

    function _setListingFee(uint _listing_fee) internal {
        if(_listing_fee < 0.1e18) revert InvalidListingFee();
        listing_fee = _listing_fee;

        emit listingFeeSet(_listing_fee);
    }
}
