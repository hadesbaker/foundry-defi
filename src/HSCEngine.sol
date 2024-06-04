// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { HadesStableCoin } from "./HadesStableCoin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HSCEnginer
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
    /// ERRORS ///
    error HSCEngine__MustBeMoreThanZero();
    error HSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error HSCEngine__NotAllowedToken();

    /// STATE VARIABLES ///
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    /// IMMUTABLE VARIABLES ///
    HadesStableCoin private immutable i_hsc;

    /// MODIFIERS ///
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert HSCEngine__MustBeMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert HSCEngine__NotAllowedToken();
        }
        _;
    }

    /// CONSTRUCTOR ///
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address hscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert HSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        // loop through address arrays and update the mappings
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_hsc = HadesStableCoin(hscAddress);
    }

    /// FUNCTIONS ///
    function depositCollateralAndMintHsc() external { }

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
    }

    function redeemCollateralForHsc() external { }

    function redeemCollateral() external { }

    function mintHsc() external { }

    function burnHsc() external { }

    function liquidate() external { }

    function getHealthFactor() external view { }
}
