// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {HadesStableCoin} from "./HadesStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/**
 * @title HSCEngine
 * @author Taki Baker Alyasri
 *
 * This engine ensures the tokens maintain a 1 token == $1 peg. This stablecoin had the properties:
 * - Exogenous
 * - Pegged to US Dollar
 * - Algorithmically Governed
 *
 * @notice This contract is the core of the HSC System. It handles all the logic for minting and redeeming HSC, as well
 * as depositing & withdrawing collateral.
 * @notice This contract is very loosely based on MakerDAO's DAI system.
 */
contract HSCEngine is ReentrancyGuard {
    //////// ERRORS ////////
    error HSCEngine__MustBeMoreThanZero();
    error HSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error HSCEngine__NotAllowedToken();
    error HSCEngine__TransferFailed();
    error HSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error HSCEngine__MintFailed();

    //////// STATE VARIABLES ////////
    uint256 private constant _ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant _PRECISION = 1e18;
    uint256 private constant _LIQUIDATION_THRESHOLD = 50;
    uint256 private constant _LIQUIDATION_PRECISION = 100;
    uint256 private constant _MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed)
        private _tokenAddressToPriceFeedAddress;
    mapping(address user => mapping(address token => uint256 amount))
        private _collateralDeposited;
    mapping(address user => uint256 amountHscMinted) private _hscMinted;

    address[] private _collateralTokens;

    //////// IMMUTABLE VARIABLES ////////
    HadesStableCoin private immutable _hsc;

    //////// EVENTS ////////
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 indexed amount
    );

    //////// MODIFIERS ////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert HSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (_tokenAddressToPriceFeedAddress[token] == address(0)) {
            revert HSCEngine__NotAllowedToken();
        }
        _;
    }

    //////// CONSTRUCTOR ////////
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address hscAddress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert HSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        // loop through address arrays and update the mappings
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            _tokenAddressToPriceFeedAddress[
                tokenAddresses[i]
            ] = priceFeedAddresses[i];

            _collateralTokens.push(tokenAddresses[i]);
        }

        _hsc = HadesStableCoin(hscAddress);
    }

    //////// EXTERNAL FUNCTIONS ////////
    function depositCollateralAndMintHsc() external {}

    ////////
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        _collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;

        emit CollateralDeposited(
            msg.sender,
            tokenCollateralAddress,
            amountCollateral
        );

        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );

        if (!success) {
            revert HSCEngine__TransferFailed();
        }
    }

    ////////
    function redeemCollateralForHsc() external {}

    ////////
    function redeemCollateral() external {}

    ////////
    function mintHsc(
        uint256 amountHscToMint
    ) external moreThanZero(amountHscToMint) nonReentrant {
        _hscMinted[msg.sender] += amountHscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = _hsc.mint(msg.sender, amountHscToMint);
        if (!minted) {
            revert HSCEngine__MintFailed();
        }
    }

    ////////
    function burnHsc() external {}

    ////////
    function liquidate() external {}

    //////// PRIVATE/INTERNAL VIEW FUNCTIONS ////////
    function _getAccountInformation(
        address user
    )
        private
        view
        returns (uint256 totalHscMinted, uint256 collateralValueInUsd)
    {
        totalHscMinted = _hscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    ////////
    function _healthFactor(address user) private view returns (uint256) {
        (
            uint256 totalHscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInformation(user);

        uint256 collateralAdjustedForThreshold = (collateralValueInUsd *
            _LIQUIDATION_THRESHOLD) / _LIQUIDATION_PRECISION;

        uint256 healthFactor = (collateralAdjustedForThreshold * _PRECISION) /
            totalHscMinted;

        return healthFactor;
    }

    ////////
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < _MIN_HEALTH_FACTOR) {
            revert HSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    //////// PUBLIC/EXTERNAL VIEW FUNCTIONS ////////
    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount deposited, and map it to the price to get the USD value
        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            address token = _collateralTokens[i];
            uint256 amount = _collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;
    }

    ////////
    function getUsdValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _tokenAddressToPriceFeedAddress[token]
        );

        (, int256 price, , , ) = priceFeed.latestRoundData();

        uint256 value = ((uint256(price) * _ADDITIONAL_FEED_PRECISION) *
            amount) / _PRECISION;

        return value;
    }
}
