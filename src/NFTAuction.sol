//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author Dliteofficial, Moralie and Victor
contract NFTAuction {
    // Variables
    uint public auctionFee;

    address public auctioneer;

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
        address listor;
        uint lastBid;
        address lastBidder;
    }

    error ZeroInput();
    error InvalidAuctionFee();
    error NotOpen();
    error MinimumStakeNotSatisfied();
    error PlaceAHigherBid();
    error OpenBidding();

    constructor(uint _auctionFee, uint _auctionDuration, address _auctioneer) {
      if(_auctionFee == 0 && _auctionDuration == 0) revert ZeroInput();
      if(_auctionFee < 0.1e18) revert InvalidAuctionFee();
      auctionFee = _auctionFee;
      auctionDuration = _auctionDuration;
      auctioneer = _auctioneer;
    }

    // Functions
    

    // @notice Allows anyone to list their NFT for auction. Listed NFTs cannot be auctioned
    /// @notice Allows anyone to list their NFT for auction. Listed NFTs cannot be auctioned
    /** @dev This function records the details of an auction including the start and endTime
    *   @dev This function is alos payable because they need to pay an auction fee to auction
    */
    // @param nftAddress This is the address of the nft we are auctioning.
    // @param tokenId This is so we transfer the right token in the collection
    // @param minimumStake The minimum amount that can be accepted for a bid

    function createAuction (address _nftAddress, uint _tokenId, uint _minimumStake) public payable {
        if(msg.value < auctionFee) revert InvalidAuctionFee();
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId); //Ensure this passes
        
        //increment the number of auctions
        auctionCounter++;
        numberOfActiveAuctions++;

        // Store the auction information
        auctions[auctionCounter - 1] = Auction({
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            minimumStake: _minimumStake,
            startTime: block.timestamp,
            endTime: block.timestamp + auctionDuration,
            lastBid: 0,
            lastBidder: address(0),
            listor: msg.sender
        });
    }

    /** 
      * @notice Allows a user to make a bid on an NFT using a unique ID after making payment
      * @dev Use the unique ID to trace the NFT so the user can make a bid on the NFT.
      * @dev the new bid has to be greater than the previous bid too
      * Tip: display the value of the last bid
     */

    function bid (uint uniqueId) public payable {
        if(!isOpen(uniqueId)) revert NotOpen();
        Auction memory AUCDetails = auctions[uniqueId];
        if(msg.value < AUCDetails.minimumStake) revert MinimumStakeNotSatisfied();
        if(msg.value <= AUCDetails.lastBid) revert PlaceAHigherBid();
        address lastBidder = AUCDetails.lastBidder;
        uint lastbid = AUCDetails.lastBid;
        AUCDetails.lastBidder = msg.sender;
        AUCDetails.lastBid = msg.value;
        auctions[uniqueId] = AUCDetails;
        //This might lead to a Denial of Service Attack. It is best you use an ERC20 token to prevent this so balances can just be recorder
        payable(lastBidder).transfer(lastbid);
    }

    /*
    * @notice: Allows the auctioneer to claim the highest bid in the auction
    * @dev onlyAuctioneer verifies that the auctioneer is the one trying to collect the funds for the NFT (uniqueID)
    * @dev pay the auctioneer the bidded amount and transfer the NFT to the winner of the bid
    */

    function claimMyFunds (uint uniqueId) public onlyAuctioneer {

        if(isOpen(uniqueId)) revert OpenBidding();

        Auction memory AUCDetails = auctions[uniqueId];

        address winner = AUCDetails.lastBidder;
        uint bidAmount = AUCDetails.lastBid;
        uint tokenId = AUCDetails.tokenId;
        address nftAddress = AUCDetails.nftAddress;
    
        require(winner != address(0), "No bids were made on this auction");
        payable(AUCDetails.listor).transfer(bidAmount);

        IERC721(nftAddress).transferFrom(address(this), winner, tokenId);

        delete auctions[uniqueId];
        numberOfActiveAuctions--;
    }



    modifier onlyAuctioneer {
        require(msg.sender == auctioneer, "Only the auctioneer can perform this action");
        _;
    }


    function isOpen(uint uniqueId) public view returns (bool) {
        return auctions[uniqueId].endTime > block.timestamp;
    }

    function getLastBid(uint uniqueId) public view returns (uint) {
        return auctions[uniqueId].lastBid;
    }
    
}
