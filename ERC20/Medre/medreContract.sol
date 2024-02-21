// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Import the staking interface and the token contract
import "./interface.sol";

/**
 * @title MedreStaking
 * @dev Implements staking functionality for the Mediterranean Real Estate Token (MEDRE).
 * The contract inherits from ReentrancyGuard to prevent reentrancy attacks,
 * Ownable for ownership management, ERC20 for standard token functionality,
 * and ERC20Burnable for token burning capabilities.
 */
contract MedreStaking is ReentrancyGuard, Ownable, ERC20, ERC20Burnable {

    string private name_ = "Mediterranean Real Estate Token"; // Name of the token
    string private symbol_ = "MEDRE"; // Symbol of the token
    uint8 private decimals_ = 3; // Number of decimals for the token
    uint256 private totalSupply_ = 1000000000; // Initial total supply of the token (1 billion)

    /**
     * @dev Constructor that mints the initial total supply to the owner's address.
     * The supply is adjusted by the token's decimals.
     */
    constructor() ERC20(name_, symbol_, decimals_) {
        _mint(owner(), totalSupply_ * (10 ** decimals_));
    }

    /**
     * @dev Pauses all token transfers. Can only be called by the contract owner.
     * This is a security feature to be used in case of an emergency.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers. Can only be called by the contract owner.
     * This allows the contract to resume normal operations after an emergency pause.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
