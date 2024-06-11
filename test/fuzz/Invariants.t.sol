// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {DeployHSC} from "../../script/DeployHSC.s.sol";
import {HadesStableCoin} from "../../src/HadesStableCoin.sol";
import {HSCEngine} from "../../src/HSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployHSC public deployer;
    HadesStableCoin public hadesStableCoin;
    HSCEngine public hscEngine;
    HelperConfig public helperConfig;

    Handler public handler;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;

    function setUp() external {
        deployer = new DeployHSC();
        (hadesStableCoin, hscEngine, helperConfig) = deployer.run();
        handler = new Handler(hscEngine, hadesStableCoin);
        targetContract(address(handler));

        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, ) = helperConfig
            .activeNetworkConfig();
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = hadesStableCoin.totalSupply();
        uint256 totalWethDeposited = ERC20Mock(weth).balanceOf(
            address(hscEngine)
        );
        uint256 totalWbtcDeposited = ERC20Mock(wbtc).balanceOf(
            address(hscEngine)
        );

        uint256 wethValue = hscEngine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = hscEngine.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("wethValue: %s", wethValue);
        console.log("wbtcValue: %s", wbtcValue);
        console.log("totalSupply: %s", totalSupply);

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_gettersCantRevert() public view {
        hscEngine.getAdditionalFeedPrecision();
        hscEngine.getCollateralTokens();
        hscEngine.getLiquidationBonus();
        hscEngine.getLiquidationBonus();
        hscEngine.getLiquidationThreshold();
        hscEngine.getMinHealthFactor();
        hscEngine.getPrecision();
        hscEngine.getHsc();
    }
}
