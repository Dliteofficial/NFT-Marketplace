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

    
}
