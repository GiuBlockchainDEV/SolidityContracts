// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Import the staking interface and the token contract
import "./interface.sol";

// The MedreStaking contract inherits ReentrancyGuard for reentrancy protection and Ownable for ownership management
contract MedreStaking is ReentrancyGuard, Ownable, ERC20, ERC20Burnable {

    // Using Math and SafeERC20 libraries for safe mathematical operations and token transfers
    using Math for uint256;
    using SafeERC20 for ERC20;

    string private name_ = "Mediterranean Real Estate Token";
    string private symbol_ = "MEDRE"; 
    uint8 private decimals_ = 3;
    uint256 private totalSupply_ = 1000000000; 

    // INITIALIZATION
    constructor() ERC20(name_, symbol_, decimals_) {
        _mint(owner(), totalSupply_ * (10 ** decimals_));
    }

    // SECURITY
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
