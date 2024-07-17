// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title ShardNFT Contract
/// @notice This contract manages the minting and burning of Shard NFTs with dynamic pricing
contract ShardNFT is ERC1155, Ownable, ReentrancyGuard, Pausable {
    // Chainlink price feed interfaces
    AggregatorV3Interface internal ethUsdPriceFeed;
    AggregatorV3Interface internal gbpUsdPriceFeed;
    
    uint256 public currentPrice;
    uint256 public constant MAX_SUPPLY = 25000;
    uint256 public constant MAX_MINT_PER_TX = 5;
    uint256 public totalMinted = 0;

    // Address of the AureusNFT contract
    address public aureusNFTAddress;

    // Events
    event ShardsMinted(address indexed to, uint256 amount);
    event ShardsBurned(address indexed from, uint256 amount);
    event PriceUpdated(uint256 newPrice);
    event ERC20Recovered(address tokenAddress, uint256 amount);
    event URIUpdated(string newUri);
    event AureusNFTAddressUpdated(address newAddress);

    /// @notice Contract constructor
    /// @param uri The base URI for token metadata
    constructor(string memory uri) ERC1155(uri) Ownable(msg.sender) {
        ethUsdPriceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        gbpUsdPriceFeed = AggregatorV3Interface(0x91FAB41F5f3bE955963a986366edAcff1aaeaa83);
        currentPrice = 1000; // Initial price set to 10 GBP in pence
    }

    /// @notice Set the address of the AureusNFT contract
    /// @param _aureusNFTAddress The address of the AureusNFT contract
    function setAureusNFTAddress(address _aureusNFTAddress) external onlyOwner {
        require(_aureusNFTAddress != address(0), "Invalid address");
        aureusNFTAddress = _aureusNFTAddress;
        emit AureusNFTAddressUpdated(_aureusNFTAddress);
    }

    /// @notice Set a new price for minting
    /// @param newPriceInPence New price in pence
    function setPrice(uint256 newPriceInPence) external onlyOwner {
        require(newPriceInPence > 0, "Price must be greater than zero");
        currentPrice = newPriceInPence;
        emit PriceUpdated(newPriceInPence);
    }

    /// @notice Mint new Shard NFTs
    /// @param amount Number of Shards to mint
    function mintShard(uint256 amount) external payable nonReentrant whenNotPaused {
        require(amount > 0 && amount <= MAX_MINT_PER_TX, "Invalid amount");
        require(totalMinted + amount <= MAX_SUPPLY, "Exceeds max supply");

        uint256 priceInEth = getEthPrice(currentPrice * amount);
        require(msg.value >= priceInEth, "Insufficient payment");
        
        _mint(msg.sender, 0, amount, "");
        totalMinted += amount;
        
        // Refund excess payment
        if(msg.value > priceInEth) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - priceInEth}("");
            require(success, "Refund failed");
        }

        emit ShardsMinted(msg.sender, amount);
    }

    /// @notice Burn Shard NFTs
    /// @param account The address to burn shards from
    /// @param amount Number of Shards to burn
    function burnShard(address account, uint256 amount) external nonReentrant whenNotPaused {
        require(msg.sender == aureusNFTAddress, "Only AureusNFT can burn shards");
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(account, 0) >= amount, "Insufficient balance");

        _burn(account, 0, amount);
        totalMinted -= amount;

        emit ShardsBurned(account, amount);
    }

    /// @notice Calculate the price in ETH based on the current GBP price
    /// @param penceAmount Amount in pence to convert
    /// @return The equivalent amount in ETH
    function getEthPrice(uint256 penceAmount) public view returns (uint256) {
        (, int256 ethUsdPrice,,,) = ethUsdPriceFeed.latestRoundData();
        (, int256 gbpUsdPrice,,,) = gbpUsdPriceFeed.latestRoundData();
        require(ethUsdPrice > 0 && gbpUsdPrice > 0, "Invalid price");
        
        uint256 ethPerUsd = uint256(ethUsdPrice); // 8 decimals
        uint256 gbpPerUsd = uint256(gbpUsdPrice); // 8 decimals
        
        uint256 numerator = penceAmount * 1e18;
        numerator = numerator * gbpPerUsd;
        uint256 denominator = ethPerUsd * 100;
        
        return numerator / denominator;
    }

    /// @notice Withdraw collected funds to the owner
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Get the total number of minted Shards
    /// @return The total number of minted Shards
    function totalSupply() public view returns (uint256) {
        return totalMinted;
    }

    /// @notice Get the remaining supply of Shards
    /// @return The number of Shards that can still be minted
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalMinted;
    }

    /// @notice Set a new URI for token metadata
    /// @param newuri The new URI to set
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        emit URIUpdated(newuri);
    }

    /// @notice Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Recover ERC20 tokens sent to this contract by mistake
    /// @param tokenAddress The address of the ERC20 token to recover
    /// @param tokenAmount The amount of tokens to recover
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit ERC20Recovered(tokenAddress, tokenAmount);
    }

    /// @notice Fallback function to receive ETH
    receive() external payable {}
}
