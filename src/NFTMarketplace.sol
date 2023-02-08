//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "src/AggregatorV3Interface.sol";

import "src/EcstasyNFT.sol";
import "src/NFTAuction.sol";

contract EcstasyMKT is ReentrancyGuard, NFTAuction {
 
   EcstasyNFT nativeNFT;
   
    /* Network: Polygon Mainnet
     * Aggregator: MATIC /USD
     * Addresss: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
     */
    constructor(uint _minting_fee) {
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        nativeNFT = new EcstasyNFT(address(this));
        setMintingFee(_minting_fee);
    }

    receive() external payable{}

    // Name of the marketplace
    string public MARKETPLACE_NAME;

    // Index of auctions
    uint256 public index = 0;

    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public constant MAX_NFT_BUYABLE = 3000;
    uint256 public constant NAME_CHANGE_PRICE = 9 * (10 ** 6);
    uint256 public constant REWARD_PER_NFT = 18 * (10 ** 6);
    uint256 public constant EXCHANGE_PER_NFT = 36 * (10 ** 6);

    uint256 private _nftSold;  // number of nft sold
    // Array with all token ids, used for enumeration
    uint256[] private _allMarketTokens;


    using Counters for Counters.Counter;
    //_tokenIds variable has the most recent minted tokenId
    Counters.Counter private _tokenIds;
    //Keeps track of the number of items sold on the marketplace
    Counters.Counter private _itemsSold;
    //owner is the contract address that created the smart contract
    address owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    uint256 listPrice = 0.01 ether;

    //The structure to store info about a listed token
    struct ListedToken {
        uint256 tokenId;
        address payable seller;
        uint256 price;
    }

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) { - //UPDATE - MORALIE
        return 1;
    }

   /*When a user clicks "Buy this NFT" on the profile page, the executeSale function is triggered.
    If the user has paid enough ETH equal to the price of the NFT, the NFT gets transferred to the new address 
    and the proceeds of the sale are sent to the seller.
    */
    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();

        //Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);
        //approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        //Transfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);
        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
    }

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

    uint public listedNFTCount = 0;
    mapping (uint => listedNFT) listings;
    mapping (address => ILD) myListings;

    uint public minting_fee; 

    function listMyNFTforSale(address _tokenAddress, uint tokenId, uint listingPrice_in_MATIC ) external nonReentrant payable{
        require(msg.value >= minting_fee, "ERR: Minting_fee Error");
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
        require(block.timestamp > listing.timestamp + 30 days, "ERR: Listing time is less than 30 days");
        listings[listedTokenID].listingPrice = listingPrice_in_MATIC;
    }

    function cancelListing (uint listingId) external {
        require(listings[listingId].listor == msg.sender, "ERR: You didn't the NFT, you cannot cancel");
        listings[listingID].NFTAddress = address(0);
        listings[listingID].listor = address(0);
        listings[listingID].timestamp = 0;
        listings[listingID].listingPrice = 0;
        listings[listingID].tokenID = 0;
    }

    function getMyNFTs() public view returns (uint totalNumberOfNFTsListed, uint[] tokenIds) {
        (totalNumberOfNFTsListed, tokenIds) = (myListings[msg.sender].total, myListings[msg.sender].tokenIds);
    }

    function getAllNFTs() public view returns (listedNFT[] memory) {
        listedNFT[] memory returnData = new listedNFT[](listedNFTCount);

        for(uint i; i < listedNFTCount; i++) {
            returnData.push(listings[i]);
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

    function setMintingFee (uint _amount) external onlyOwner {
        require(_amount > 0, "ERR: Zero Amount");
        minting_fee = _amount;
    }

    function buyNFT_Single(uint listingID) external nonReentrant payable{
       listedNFT memory NFTinfo = listings[listingID];
       require(msg.value >= NFTinfo.listingPrice, "ERR: You didn't pay enough for the NFT");
       address tokenAddress = NFTinfo.NFTAddress;
       address tokenId = NFTinfo.tokenID;
       address listor = NFTinfo.listor;
       //Remove the NFT from myListings. - Moralie
       listings[listingID].NFTAddress = address(0);
       listings[listingID].listor = address(0);
       listings[listingID].timestamp = 0;
       listings[listingID].listingPrice = 0;
       listings[listingID].tokenID = 0;
       IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
       _makePaymentToListor(listor, msg.value); // Create a payment Function - Victor
    }
    function _makePaymentToListor(address to, uint value) internal {
       to.transfer(value);
    }
}
