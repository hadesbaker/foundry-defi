// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {DeployHSC} from "../../script/DeployHSC.s.sol";
import {HadesStableCoin} from "../../src/HadesStableCoin.sol";
import {HSCEngine} from "../../src/HSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OpenInvariantsTest is StdInvariant, Test {
    DeployHSC public deployer;
    HadesStableCoin public hadesStableCoin;
    HSCEngine public hscEngine;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;

    function setUp() external {
        deployer = new DeployHSC();
        (hadesStableCoin, hscEngine, helperConfig) = deployer.run();
        targetContract(address(hscEngine));

        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, ) = helperConfig
            .activeNetworkConfig();
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = hadesStableCoin.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(hscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(hscEngine));

        uint256 wethValue = hscEngine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = hscEngine.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("wethValue: %s", wethValue);
        console.log("wbtcValue: %s", wbtcValue);
        console.log("totalSupply: %s", totalSupply);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
