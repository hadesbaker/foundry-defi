// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployHSC} from "../../script/DeployHSC.s.sol";
import {HadesStableCoin} from "../../src/HadesStableCoin.sol";
import {HSCEngine} from "../../src/HSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract HSCEngineTest is StdCheats, Test {
    DeployHSC public deployer;
    HadesStableCoin public hadesStableCoin;
    HSCEngine public hscEngine;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    address public user = makeAddr("user");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant AMOUNT_TO_MINT = 100 ether;

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(hscEngine), AMOUNT_COLLATERAL);
        hscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

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
            vm.deal(user, STARTING_USER_BALANCE);
        }

        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }

    //////// CONSTRUCTOR TESTS ////////
    address[] public tokenAddresses;
    address[] public feedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(
            HSCEngine
                .HSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength
                .selector
        );

        new HSCEngine(tokenAddresses, feedAddresses, address(hadesStableCoin));
    }

    //////// PRICE TESTS ////////
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30_000e18;
        uint256 actualUsd = hscEngine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 expectedWeth = 0.05 ether;
        uint256 amountWeth = hscEngine.getTokenAmountFromUsd(weth, 100 ether);
        assertEq(amountWeth, expectedWeth);
    }

    //////// DEPOSIT COLLATERAL TESTS ////////
    function testRevertsIfCollateralZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(hscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(HSCEngine.HSCEngine__MustBeMoreThanZero.selector);
        hscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock(
            "RAN",
            "RAN",
            user,
            STARTING_USER_BALANCE
        );

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                HSCEngine.HSCEngine__NotAllowedToken.selector,
                address(randToken)
            )
        );
        hscEngine.depositCollateral(address(randToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo()
        public
        depositedCollateral
    {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = hscEngine
            .getAccountInformation(user);

        uint256 expectedDepositedAmount = hscEngine.getTokenAmountFromUsd(
            weth,
            collateralValueInUsd
        );

        assertEq(totalDscMinted, 0);
        assertEq(expectedDepositedAmount, AMOUNT_COLLATERAL);
    }

    function testCanDepositCollateralWithoutMinting()
        public
        depositedCollateral
    {
        uint256 userBalance = hadesStableCoin.balanceOf(user);
        assertEq(userBalance, 0);
    }
}
