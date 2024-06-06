// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HadesStableCoin} from "../src/HadesStableCoin.sol";
import {HSCEngine} from "../src/HSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployHSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (HadesStableCoin, HSCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!

        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        HadesStableCoin hadesStableCoin = new HadesStableCoin();
        HSCEngine hscEngine = new HSCEngine(
            tokenAddresses,
            priceFeedAddresses,
            address(hadesStableCoin)
        );
        hadesStableCoin.transferOwnership(address(hscEngine));
        vm.stopBroadcast();
        return (hadesStableCoin, hscEngine, helperConfig);
    }
}
