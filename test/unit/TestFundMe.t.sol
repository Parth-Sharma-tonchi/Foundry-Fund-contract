//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testOwner() public{
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testMinimumUsdToFund() public{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testPriceFeedVersionIsAccurate() public{
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public{
        vm.expectRevert(); // After it, we expect revert.
        fundMe.fund();
    }

    function testFundVariables() public{

        vm.prank(USER);

        fundMe.fund{value:SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        assertEq(amountFunded, SEND_VALUE);
        assertEq(USER, fundMe.getFunder(0));
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER); 
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded(){
        //arrange
        uint256 startingfundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingfundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingfundMeBalance, 0);
        assertEq(startingfundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }   

    function testWithdrawWithMultipleFunders() public funded(){
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i<numberOfFunders; ++i){
            //vm.prank to get an address
            //vm.deal to add some eth to it. And instead of it we are gonna use hoax
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingfundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingfundMeBalance = address(fundMe).balance;

        assert(endingfundMeBalance == 0);
        assert(startingOwnerBalance + startingfundMeBalance == endingOwnerBalance);
        console.log(fundMe.getOwner());
    }

    function testWithdrawWithMultipleFundersCheaper() public funded(){
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i<numberOfFunders; ++i){
            //vm.prank to get an address
            //vm.deal to add some eth to it. And instead of it we are gonna use hoax
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingfundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingfundMeBalance = address(fundMe).balance;

        assert(endingfundMeBalance == 0);
        assert(startingOwnerBalance + startingfundMeBalance == endingOwnerBalance);
        console.log(fundMe.getOwner());
    }

    function testGetPriceFeedReturns() public view {
        AggregatorV3Interface priceFeed = fundMe.getPriceFeed();
        assert(priceFeed != AggregatorV3Interface(address(0)));
    }
}