//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author Dliteofficial, Moralie and Victor
contract NFTAuction {
    // Variables
    uint public auctionFee;

    //Auctioning duration, after which every auction ends. An auction cannot be stopped.
    uint public auctionDuration;

    // @notice Total number of active auctions
    uint public numberOfActiveAuctions = 0;

    uint public auctionCounter = 0;

    mapping (uint => Auction) public auctions;

    struct Auction {
        address nftAddress;
        uint tokenId;
        uint minimumStake;
        uint startTime;
        uint endTime;

        uint lastBid;
        address lastBidder;
    }

    // Functions
    

    // @notice Allows anyone to list their NFT for auction. Listed NFTs cannot be auctioned
    /// @notice Allows anyone to list their NFT for auction. Listed NFTs cannot be auctioned
    /** @dev This function records the details of an auction including the start and endTime
      * @dev This function is alos payable because they need to pay an auction fee to auction
    */
    // @param nftAddress This is the address of the nft we are auctioning.
    // @param tokenId This is so we transfer the right token in the collection
    // @param minimumStake The minimum amount that can be accepted for a bid

    function createAuction (address nftAddress, uint tokenId, uint minimumStake) public payable {
        require(msg.value >= auctionFee, "ERR: AUCTION FEE NOT MET");
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId); //Ensure this passes
        
        //increment the number of auctions
        auctionCounter++;
        numberOfActiveAuctions++;

        // Store the auction information
        auctions[auctionCounter] = Auction({
            nftAddress: nftAddress,
            tokenId: tokenId,
            minimumStake: minimumStake,
            startTime: block.timestamp,
            endTime: block.timestamp + auctionDuration,
            lastBid: 0,
            lastBidder: address(0)
        });
    }

    /** 
      * @notice Allows a user to make a bid on an NFT using a unique ID after making payment
      * @dev Use the unique ID to trace the NFT so the user can make a bid on the NFT.
      * @dev the new bid has to be greater than the previous bid too
      * Tip: display the value of the last bid
     */

    function bid (uint uniqueId) public payable {
        require(isOpen(uniqueId), "Auction is closed");
        require(msg.value > auctions[uniqueId].lastBid, "Bid must be higher than the last bid");
        require(msg.value >= auctions[uniqueId].minimumStake, "Bid must meet the minimum stake");
        auctions[uniqueId].lastBid = msg.value;
        auctions[uniqueId].lastBidder = msg.sender;
    }

    /*
    * @notice: Allows the auctioneer to claim the highest bid in the auction
    * @dev onlyAuctioneer verifies that the auctioneer is the one trying to collect the funds for the NFT (uniqueID)
    * @dev pay the auctioneer the bidded amount and transfer the NFT to the winner of the bid
    */

    function claimMyFunds (uint uniqueId) public onlyAuctioneer {

        require(!isOpen(uniqueId), "Auction is still open");

        address winner = auctions[uniqueId].lastBidder;

        uint bidAmount = auctions[uniqueId].lastBid;
    
        require(winner != address(0), "No bids were made on this auction");
    
        //bool transferSuccess = auctions[uniqueId].nftAddress.transferFrom(address(this), winner, auctions[uniqueId].tokenId);
    
        //require(transferSuccess, "Transfer failed");
    
        // Transfer the winning bid amount to the auctioneer
        address payable auctioneer = payable(address(this));
        auctioneer.transfer(bidAmount);
    
        delete auctions[uniqueId];
    
        numberOfActiveAuctions--;
    }



    modifier onlyAuctioneer {
        require(msg.sender == address(this), "Only the auctioneer can perform this action");
        _;
    }


    function isOpen(uint uniqueId) public view returns (bool) {
        return auctions[uniqueId].endTime > block.timestamp;
    }

    function getLastBid(uint uniqueId) public view returns (uint) {
        return auctions[uniqueId].lastBid;
    }
    
}
