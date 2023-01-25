//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title This contract provides the functionalities needed to auction NFTs
/// @author Dliteofficial, VictorFawole & Moralie

contract NFTAuction {

    uint public actionFee; //To be set later

    //Auctioning duration, after which every auction ends, 
    //An auction cannot be stopped
    uint public auctionDuration;

    /// @notice Total number of auctions
    uint public numberOfAuctions = 0;

    /// @notice Total number of active auctions
    uint public numberOfActiveAuctions = 0;

    uint public auctionCounter = 0;

    /// @notice Allows anyone to list their NFT for auction. Listed NFTs cannot be auctioned
    /** @dev This function records the details of an auction including the start and endTime
      * @dev This function is alos payable because they need to pay an auction fee to auction
    */
    /// @param nftAddress This is the address of the nft we are auctioning.
    /// @param tokenId This is so we transfer the right token in the collection
    /// @param minimumStake The minimum amount that can be accepted for a bid

    function createAuction (
        address nftAddress,
        uint tokenId,
        uint minimumStake
        ) public payable {

    }

    /** 
      * @notice Allows a user to make a bid on an NFT using a unique ID after making payment
      * @dev Use the unique ID to trace the NFT so the user can make a bid on the NFT.
      * @dev the new bid has to be greater than the previous bid too
     */
    function bid (uint uniqueId) public payable {

    }

    /** 
      * @notice Allows the auctioneer to claim the highest bid in the auction
      * @dev onlyAuctioneer verifies that the auctioneer is the one trying to collect the funds for the NFT (uniqueID)
      * @dev pay the auctioneer the bidded amount and transfer the NFT to the winner of the bid
     */
    function claimMyFunds (uint uniqueId) public onlyAuctioneer {

    }

    /// @notice checks if bidding is still open for a NFT
    /// @dev returns a true/false if bidding is still open or not
    function isOpen(uint256 uniqueID) public view returns (bool) {

    }

    /// @notice provide the last bidding price on the NFT
    /// @return returns the last bidding price of the NFT
    function getLastBid(uint256 uniqueID) public view returns (uint256) {

    }
}