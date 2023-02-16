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
        marketplace = new EcstasyMKT(0.1e18, 0.1e18, 3 days);
        vm.label (address(marketplace), "Ecstasy Marketplace Contract");

        nativeNFTAddress = address(marketplace.nativeNFT());

        bob = makeAddr("bob");
        vm.label(bob, "USER: BOB");
        vm.deal(bob, 1_000e18);

        alice = makeAddr("Alice");
        vm.label(bob, "USER: Alice");
        vm.deal(alice, 1_000e18);
    }

    function test__getLatestPrice() public {
        emit log_named_int ("MATIC latest price is ", marketplace.getLatestPrice());
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
        (, , , uint listingPrice, ) = marketplace.listings(1);
        assertEq(listingPrice, 1e18, "ERR: Listing Price of the NFT != 1 Ether");
        vm.warp(block.timestamp + 30 days);
        marketplace.updateListingPrice(1, 2e18);
        (, , , listingPrice, ) = marketplace.listings(1);
        assertEq(listingPrice, 2e18, "ERR: Listing Price of the NFT != 2 Ether");
        vm.stopPrank();
    }

    function testFail__updateListingPriceNot30Days() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        (, , , uint listingPrice, ) = marketplace.listings(1);
        assertEq(listingPrice, 1e18, "ERR: Listing Price of the NFT != 1 Ether");
        marketplace.updateListingPrice(1, 2e18);
        (, , , listingPrice, ) = marketplace.listings(1);
        assertEq(listingPrice, 2e18, "ERR: Listing Price of the NFT != 2 Ether");
    }

    function testFail__updateListingPriceNotListor() public {
        vm.startPrank(alice);
        marketplace.mintEcstasy{value: 0.1e18}();
        IERC721(nativeNFTAddress).approve(address(marketplace), 0);
        marketplace.listMyNFTforSale{value: 0.1e18}(nativeNFTAddress, 0, 1e18);
        (, , , uint listingPrice, ) = marketplace.listings(1);
        assertEq(listingPrice, 1e18, "ERR: Listing Price of the NFT != 1 Ether");
        vm.stopPrank();
        vm.warp(block.timestamp + 30 days);
        vm.startPrank(bob);
        marketplace.updateListingPrice(1, 2e18);
        (, , , listingPrice, ) = marketplace.listings(1);
        assertEq(listingPrice, 2e18, "ERR: Listing Price of the NFT != 2 Ether");
        vm.stopPrank();
    }
}
