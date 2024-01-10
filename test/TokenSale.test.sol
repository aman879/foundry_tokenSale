// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {TokenSale} from "../src/TokenSale.sol";

contract TokenSaleTest is Test {
    TokenSale public ts;

    event TokensPurchased(address indexed buyer, uint256 amount, bool isPresale);

    function setUp() public{
        ts = new TokenSale(
            2000000000000000000,
            100000000000000000,
            500000000000000000,
            2000000000000000000,
            100000000000000000,
            500000000000000000  
        );
    }

    function testName() public {
        assertEq(ts.name(), "ProjectToken");
    }

    function testSymbol() public {
        assertEq(ts.symbol(), "PT");
    }

    function testStartingState() public {
        assertFalse(ts.presaleEnded());
        assertFalse(ts.publicSaleStarted());
        assertFalse(ts.publicSaleEnded());
    }

    function testTokenState() public {
        assertEq(ts.getPreSaleCap(), 2000000000000000000); 
        assertEq(ts.getPresaleMinConstributionDetails(), 100000000000000000);
        assertEq(ts.getPresaleMaxConstributionDetails(), 500000000000000000);
        assertEq(ts.getPublicSaleCap(), 2000000000000000000); 
        assertEq(ts.getPublicSaleMinConstributionDetails(), 100000000000000000);
        assertEq(ts.getPublicSaleMaxConstributionDetails(), 500000000000000000);
    }

    function testPreSale() public {
        address someRondomUser = vm.addr(1);
        vm.startPrank(someRondomUser);
        vm.deal(someRondomUser, 1 ether);
        vm.expectRevert("Minimum contribution not fulfilled");
        ts.presale{value: 0.001 ether}();

        vm.expectRevert("Exceeds Presale Maximum contribution");
        ts.presale{value: 0.6 ether}();

        uint256 amount = 0.3 ether;
        vm.expectEmit(true, false, false, true);
        emit TokensPurchased(someRondomUser, amount, true);
        ts.presale{value: amount}();
        vm.stopPrank();


        ts.endPreSale();
        assertTrue(ts.presaleEnded());

        ts.startPublicSale();
        assertTrue(ts.publicSaleStarted());

        vm.prank(someRondomUser);
        vm.expectRevert("Presale has Ended");
        ts.presale{value: 0.01 ether}();
        vm.stopPrank();
    }

    function testPreSaleMaxError() public{
        address someRondomUser = vm.addr(1);
        vm.deal(someRondomUser, 1 ether);
        uint256 amount = 0.3 ether;
        vm.startPrank(someRondomUser);
        
        ts.presale{value: amount}();

        vm.expectRevert("Exceeds Presale Maximum contribution");
        ts.presale{value: amount}();
    }

    function testPresaleConstributorArray() public {
        address someRandomUser = vm.addr(1);
        vm.deal(someRandomUser, 1 ether);

        vm.startPrank(someRandomUser);

        ts.presale{value: 0.2 ether}();
        assertEq(ts.totalPresaleConstributor(), 1);

        ts.presale{value: 0.2 ether}();
        assertEq(ts.presaleConstributor(someRandomUser), 0.4 ether);
        vm.stopPrank();

        address someRandomUser2 = vm.addr(2);
        vm.deal(someRandomUser2, 1 ether);

        vm.startPrank(someRandomUser2);

        ts.presale{value: 0.5 ether}();
        assertEq(ts.totalPresaleConstribution(), 0.9 ether);
    }

    function testIncreasePresaleCap() public {
        address someRandomUser = vm.addr(1);

        vm.prank(someRandomUser);
        vm.expectRevert();
        ts.increasePresaleCap(0.3 ether);

        ts.increasePresaleCap(0.3 ether);
        assertEq(ts.getPreSaleCap(), 2.3 ether);

        ts.endPreSale();
        vm.expectRevert("Presale has Ended");
        ts.increasePresaleCap(0.1 ether);
    }

    function testPublicSaleState() public {
        uint256 amount = 0.3 ether;
        vm.expectRevert("Presale running");
        ts.publicSale{value: amount}();

        ts.endPreSale();
        vm.expectRevert("Public sale has not started yet");
        ts.publicSale{value: amount}();

        ts.endPublicSale();
        vm.expectRevert("Public sale has Ended");
        ts.publicSale{value: amount}();
    }

    function testPublicSale() public {
        address someRandomUser = vm.addr(1);
        vm.deal(someRandomUser, 1 ether);
        uint256 amount = 0.3 ether;

        ts.endPreSale();
        ts.startPublicSale();

        vm.startPrank(someRandomUser);

        vm.expectRevert("Minimum criteria do not match");
        ts.publicSale{value: 0.1 ether}();

        vm.expectRevert("Maximum contribution has been reached");
        ts.publicSale{value: 0.6 ether}();

        vm.expectEmit(true, false, false, true);
        emit TokensPurchased(someRandomUser, amount, false);
        ts.publicSale{value: amount}();

        vm.expectRevert("Maximum contribution has been reached");
        ts.publicSale{value: amount}();
        vm.stopPrank();
    }

    function testPublicSaleCap() public {

        address someRandomUser = vm.addr(5);
        vm.deal(someRandomUser, 4 ether);

        ts.endPreSale();
        ts.startPublicSale();

        address[] memory someRandomUsers = new address[](6);

        for (uint256 i = 1; i <= 4; i++) {
            someRandomUsers[i - 1] = vm.addr(i);
            vm.deal(someRandomUsers[i - 1], 3 ether);

            vm.prank(someRandomUsers[i - 1]);
            ts.publicSale{value: 0.5 ether}();
        }
    
        vm.prank(someRandomUser);
        vm.expectRevert("Exceed public sale cap");
        ts.publicSale{value: 0.2 ether}();
    }

    function testIncreasePublicSaleCap() public {
        address someRandomUser = vm.addr(1);

        vm.prank(someRandomUser);
        vm.expectRevert();
        ts.increasePublicSaleCap(0.3 ether);

        ts.increasePublicSaleCap(0.3 ether);
        assertEq(ts.getPublicSaleCap(), 2.3 ether);

        ts.endPreSale();
        ts.startPublicSale();

        ts.endPublicSale();
        vm.expectRevert("Public sale has Ended");
        ts.increasePublicSaleCap(0.1 ether);
    }


}