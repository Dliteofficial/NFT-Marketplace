// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/EcstasyMKT.sol";

contract EcstasyMKTTest is Test {

    EcstasyMKT marketplace;
    address nativeNFTAddress;
    address bob;
    address alice;

    function setUp() public {
        marketplace = new EcstasyMKT(0.1e18, 0.1e18, 3 days, 0.1e18);
        vm.label (address(marketplace), "Ecstasy Marketplace Contract");

        nativeNFTAddress = address(marketplace.nativeNFT());

        bob = makeAddr("bob");
        vm.label(bob, "USER: BOB");
        vm.deal(bob, 1_000e18);

        alice = makeAddr("Alice");
        vm.label(bob, "USER: Alice");
        vm.deal(alice, 1_000e18);
    }

    function test__mintEcstasy__fuzz(uint amount) public {
        vm.prank(bob);
        marketplace.mintEcstasy{value: amount}();
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), bob);
    }

    function test__mintEcstasy__rightAmount() public {
        vm.prank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), alice);
    }

    function test__listMyNFTforSale() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), address(marketplace), "ERR: NFT Transfer failed");
        assertEq(marketplace.listedNFTCount(), 2, "ERR: ListedNFTCount!=2");
        vm.stopPrank();
    }

    function test__updateListingPrice() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        (, , , uint listingPrice, , ) = marketplace.listings(1);
        assertEq(listingPrice, 1e18, "ERR: Listing Price of the NFT != 1 Ether");
        vm.warp(block.timestamp + 30 days);
        marketplace.updateListingPrice(1, 2e18);
        (, , , listingPrice, , ) = marketplace.listings(1);
        assertEq(listingPrice, 2e18, "ERR: Listing Price of the NFT != 2 Ether");
        vm.stopPrank();
    }

    function testFail__updateListingPriceNot30Days() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        (, , , uint listingPrice, , ) = marketplace.listings(1);
        assertEq(listingPrice, 1e18, "ERR: Listing Price of the NFT != 1 Ether");
        marketplace.updateListingPrice(1, 2e18);
        (, , , listingPrice, , ) = marketplace.listings(1);
        assertEq(listingPrice, 2e18, "ERR: Listing Price of the NFT != 2 Ether");
    }

    function testFail__updateListingPriceNotListor() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        (, , , uint listingPrice, , ) = marketplace.listings(1);
        assertEq(listingPrice, 1e18, "ERR: Listing Price of the NFT != 1 Ether");
        vm.stopPrank();
        vm.warp(block.timestamp + 30 days);
        vm.startPrank(bob);
        marketplace.updateListingPrice(1, 2e18);
        (, , , listingPrice, , ) = marketplace.listings(1);
        assertEq(listingPrice, 2e18, "ERR: Listing Price of the NFT != 2 Ether");
        vm.stopPrank();
    }

    function test__cancelListing() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        marketplace.cancelListing(1);
        vm.stopPrank();
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), alice);
        (, , , , , bool canceled_sold) = marketplace.listings(1);
        assertTrue(canceled_sold);
    }

    function testFail__cancelListingNotOwner() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        vm.stopPrank();
        vm.startPrank(bob);
        marketplace.cancelListing(1);
        vm.stopPrank();
    }

    function testFail__cancelListingAlreadyCanceledorSold() public { //Also cover buyNFT sold
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        marketplace.cancelListing(1);
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), alice);
        (, , , , , bool canceled_sold) = marketplace.listings(1);
        assertTrue(canceled_sold);

        //Calling cancel on an already cancelled listing as alice
        marketplace.cancelListing(1);
        vm.stopPrank();
    }

    function test__buyNFT() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), address(marketplace), "ERR: NFT Transfer failed");
        assertEq(marketplace.listedNFTCount(), 2, "ERR: ListedNFTCount!=2");
        vm.stopPrank();

        vm.startPrank(bob);
        marketplace.buyNFT{value:1e18}(1);
        vm.stopPrank();

        (, , , , , bool canceled_sold) = marketplace.listings(1);
        assertTrue(canceled_sold);
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), bob, "ERR: Bob buy NFT transaction didnt go through");
        emit log_named_uint("Alice's MATIC balance is ", address(alice).balance);
        emit log_named_uint("Bob's MATIC balance is ", address(bob).balance);
    }

    function test__buyNFT__Fuzz(uint amount) public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), address(marketplace), "ERR: NFT Transfer failed");
        assertEq(marketplace.listedNFTCount(), 2, "ERR: ListedNFTCount!=2");
        vm.stopPrank();

        vm.startPrank(bob);
        marketplace.buyNFT{value:amount}(1);
        vm.stopPrank();

        (, , , , , bool canceled_sold) = marketplace.listings(1);
        assertTrue(canceled_sold);
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), bob, "ERR: Bob buy NFT transaction didnt go through");
    }

    function test__createAuction() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.createAuction{value:0.1e18}(nativeNFTAddress, 0, 0.1e18);
        vm.stopPrank();

        (address nftAddress, uint tokenId, uint minimumStake, , , , , ) = marketplace.auctions(0);

        assertEq(nftAddress, nativeNFTAddress, "nft Address != Native NFT");
        assertEq(tokenId, 0, "tokenId != 0");
        assertEq(minimumStake, 0.1e18, "minimumStake != 0.1e18");
    }

    function testFail__bid () public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.createAuction{value:0.1e18}(nativeNFTAddress, 0, 0.1e18);
        vm.stopPrank();

        address[3] memory user;
        uint minimumStake = 0.1e18;

        for(uint i=1; i < 3; i++) { //I dont want a situation of address zero
            user[i] = address(uint160(i));
            vm.deal(user[i], 1_000e18);
            vm.startPrank(user[i]);
            marketplace.bid{value: minimumStake}(0); //increase by 10% for a new bid
            vm.stopPrank();
        }
    }

    function testFail__claimMyFunds__NotEnoughTimeHasPassed () public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.createAuction{value:0.1e18}(nativeNFTAddress, 0, 0.1e18);
        vm.stopPrank();

        vm.prank(bob);
        marketplace.bid{value: 0.1e18}(0);

        vm.prank(marketplace.auctioneer());
        marketplace.claimMyFunds(0);
    }

    function testFail__claimMyFunds__NotAuctioneer () public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.createAuction{value:0.1e18}(nativeNFTAddress, 0, 0.1e18);
        vm.stopPrank();

        vm.prank(bob);
        marketplace.bid{value: 0.1e18}(0);

        vm.prank(bob);
        marketplace.claimMyFunds(0);
    }

    function test__claimMyFunds() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.createAuction{value:0.1e18}(nativeNFTAddress, 0, 0.1e18);
        vm.stopPrank();

        vm.prank(bob);
        marketplace.bid{value: 0.1e18}(0);

        vm.warp(block.timestamp + 3 days);

        vm.prank(marketplace.auctioneer());
        marketplace.claimMyFunds(0);

        //check that values are = zero and that bob now owns the nft
        assertEq(address(alice).balance, (9999e17));
        assertEq(IERC721(nativeNFTAddress).ownerOf(0), bob);

        (address nftAddress, , , ,  , , , ) = marketplace.auctions(0);

        assertEq(nftAddress, address(0));
    }
}
