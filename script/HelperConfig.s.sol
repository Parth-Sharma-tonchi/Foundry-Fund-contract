//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;

    struct NetworkConfig{
        address priceFeedAddress;
    }

    constructor(){
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        }else if(block.chainid == 1){
            activeNetworkConfig = getMainnetEthConfig();
        }else{
            activeNetworkConfig = getOrCreateLocalhostEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory sepoliaPriceFeed;
        sepoliaPriceFeed.priceFeedAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;        
        return sepoliaPriceFeed;
    }

    function getMainnetEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory mainnetPriceFeed = NetworkConfig({priceFeedAddress:0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return mainnetPriceFeed;
    }

    function getOrCreateLocalhostEthConfig() public returns(NetworkConfig memory){
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER);
        vm.stopBroadcast();
        NetworkConfig memory localHostEthConfig = NetworkConfig({priceFeedAddress: address(mockV3Aggregator)});
        return localHostEthConfig;
    }
}