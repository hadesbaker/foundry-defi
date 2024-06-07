// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployHSC} from "../../script/DeployHSC.s.sol";
import {HadesStableCoin} from "../../src/HadesStableCoin.sol";
import {HSCEngine} from "../../src/HSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract HSCEngineTest is Test {
    DeployHSC public deployer;
    HadesStableCoin public hadesStableCoin;
    HSCEngine public hscEngine;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    address public USER = makeAddr("user");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant AMOUNT_TO_MINT = 100 ether;

    function setUp() public {
        deployer = new DeployHSC();
        (hadesStableCoin, hscEngine, helperConfig) = deployer.run();
        (
            ethUsdPriceFeed,
            btcUsdPriceFeed,
            weth,
            wbtc,
            deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (block.chainid == 31337) {
            vm.deal(USER, STARTING_USER_BALANCE);
        }

        ERC20Mock(weth).mint(USER, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(USER, STARTING_USER_BALANCE);
    }

    //////// PRICE TESTS ////////
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30_000e18;
        uint256 actualUsd = hscEngine.getUsdValue(weth, ethAmount);

        assertEq(expectedUsd, actualUsd);
    }

    //////// DEPOSIT COLLATERAL TESTS ////////
    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(hscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(HSCEngine.HSCEngine__MustBeMoreThanZero.selector);
        hscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
