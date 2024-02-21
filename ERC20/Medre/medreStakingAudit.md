# Audit Report for MedreStaking Smart Contract

## Summary
The `MedreStaking` contract implements staking functionality for the `medreToken` ERC20 token. It utilizes the `Math` library for arithmetic operations and `SafeERC20` for safe token transfers. Key features include staking, unstaking, claiming rewards, and compounding dividends.

## Contract Overview
- **Contract Name:** `MedreStaking`
- **Solidity Version:** ^0.8.24
- **Key Libraries/Interfaces:** `Math`, `SafeERC20`, `IERC20`

## Key Findings
### Security Concerns
1. **Reentrancy Protection**: The contract correctly uses the `nonReentrant` modifier for state-changing external functions such as `stake`, `unstake`, `compoundDividends`, and `claimRewards` to prevent reentrancy attacks.
2. **Access Control**: Functions that should be restricted to the contract owner, like `addRewardsToPool`, properly utilize the `onlyOwner` modifier.

### Potential Improvements
1. **Penalty Calculation and Distribution**: The contract applies penalties for early unstaking and out-of-grace-period actions. It is advisable to ensure that the penalty mechanisms are clear and well-documented for transparency.
2. **Dividends Calculation**: The dividends calculation uses a fixed ratio and divisor. Consider implementing a more dynamic approach to adjust the rewards based on changing conditions like total staked amount and rewards pool size.

### Gas Optimization
- **Looping through Stakes**: The `getStakes` function retrieves all stakes for a user, which could lead to high gas costs if a user has a large number of stakes. Consider optimizing data retrieval or implementing pagination.
  
## Conclusion
The `MedreStaking` contract provides foundational staking functionality with an emphasis on security through reentrancy guards and access control. However, attention should be given to optimizing gas usage and ensuring the penalty and rewards mechanisms are transparent and efficient.
