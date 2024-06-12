// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {HSCEngine, AggregatorV3Interface} from "../../src/HSCEngine.sol";
import {HadesStableCoin} from "../../src/HadesStableCoin.sol";

contract Handler is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    HSCEngine public hscEngine;
    HadesStableCoin public hadesStableCoin;

    MockV3Aggregator public ethUsdPriceFeed;
    MockV3Aggregator public btcUsdPriceFeed;

    ERC20Mock public weth;
    ERC20Mock public wbtc;

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(HSCEngine _hscEngine, HadesStableCoin _hadesStableCoin) {
        hscEngine = _hscEngine;
        hadesStableCoin = _hadesStableCoin;

        address[] memory collateralTokens = hscEngine.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        ethUsdPriceFeed = MockV3Aggregator(
            hscEngine.getCollateralTokenPriceFeed(address(weth))
        );
        btcUsdPriceFeed = MockV3Aggregator(
            hscEngine.getCollateralTokenPriceFeed(address(wbtc))
        );
    }

    //////// HSCEngine ////////
    function mintAndDepositCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(hscEngine), amountCollateral);
        hscEngine.depositCollateral(address(collateral), amountCollateral);
    }

    ////////
    function redeemCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        hscEngine.redeemCollateral(address(collateral), amountCollateral);
    }

    ////////
    function burnHsc(uint256 amountHsc) public {
        amountHsc = bound(amountHsc, 0, hadesStableCoin.balanceOf(msg.sender));
        hadesStableCoin.burn(amountHsc);
    }

    ////////
    function mintDsc(uint256 amountHsc) public {
        amountHsc = bound(amountHsc, 0, MAX_DEPOSIT_SIZE);
        hadesStableCoin.mint(msg.sender, amountHsc);
    }

    ////////
    function liquidate(
        uint256 collateralSeed,
        address userToBeLiquidated,
        uint256 debtToCover
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        hscEngine.liquidate(
            address(collateral),
            userToBeLiquidated,
            debtToCover
        );
    }

    //////// HadesStableCoin ////////
    function transferHsc(uint256 amountHsc, address to) public {
        amountHsc = bound(amountHsc, 0, hadesStableCoin.balanceOf(msg.sender));
        vm.prank(msg.sender);
        hadesStableCoin.transfer(to, amountHsc);
    }

    //////// Aggregator ////////
    function updateCollateralPrice(
        uint128,
        /* newPrice */ uint256 collateralSeed
    ) public {
        int256 intNewPrice = 0;
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        MockV3Aggregator priceFeed = MockV3Aggregator(
            hscEngine.getCollateralTokenPriceFeed(address(collateral))
        );

        priceFeed.updateAnswer(intNewPrice);
    }

    //////// Helper Functions ////////
    function _getCollateralFromSeed(
        uint256 collateralSeed
    ) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
