//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./NFTCollection.sol";
import "./ERC20.sol"; // Victor's contract
import "src/AggregatorV3Interface.sol";
import "src/NativeNFT.sol";

contract  EcstasyMKT is ERC721URIStorage, ReentrancyGuard {
 
   NativeNFT nativeNFT;
   
   /* Network: Goerli
     * Aggregator: ETH/USD
     */
   constructor() ERC721("MoNFTMarketPlace", "MoNFTM") {
        owner =  msg.sender;
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        nativeNFT = new nativeNFT();
    }

    receive() external payable{}

    // Name of the marketplace
    string public MoMo;

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
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    uint256 listPrice = 0.01 ether;

    //The structure to store info about a listed token
    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;

    function updateListingPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    //The first time a token is created, it is listed here
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        //Increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        //Map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newTokenId, tokenURI);

        //Helper function to update Global variables and emit an event
        createListedToken(newTokenId, price);

        return newTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Hopefully sending the correct price");
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), tokenId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            true
        );
    }
    
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;

        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=0;i<nftCount;i++)
        {
            uint currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }
    
    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                uint currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
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

    //We can add a reselltoken function in the future
    //In that case, tokens won't be listed by default but users can send a request to actually list a token
    //Currently NFTs are listed by default

     function numberOfNftsSold() public view returns (uint256) {
        return _nftSold;
    }
        
    function buy(uint256 numberOfNfts) public payable {
        require(_nftSold < MAX_NFT_BUYABLE, "Sale has already ended. Please STAKE tokens to earn more!");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 10, "You may not buy more than 10 NFTs at once");
        //require(_nftSold.add(numberOfNfts) <= MAX_NFT_BUYABLE, "Exceeds MAX_NFT_BUYABLE");
        //_nftSold = _nftSold.add(numberOfNfts);  // update

    }

        function getLatestPrice() public view returns (int) {
        ( , int price, , , ) = priceFeed.latestRoundData();

        return price;
    }
}