// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A Foundry Defi Project
 * @author Taki Baker Alyasri
 *
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 */
contract HadesStableCoin is ERC20Burnable, Ownable {
    //////// ERRORS ////////
    error HadesStableCoin__MustBeMoreThanZero();
    error HadesStableCoin__BurnAmountExceedsBalance();
    error HadesStableCoin__NotZeroAddress();

    //////// CONSTRUCTOR ////////
    constructor() ERC20("HadesStableCoin", "HSC") {}

    //////// FUNCTIONS ////////
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert HadesStableCoin__MustBeMoreThanZero();
        }
        if (balance <= _amount) {
            revert HadesStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    ////////
    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert HadesStableCoin__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert HadesStableCoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
