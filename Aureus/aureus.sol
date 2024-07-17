// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IShardNFT {
    function burnShard(address account, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

/**
 * @title AureusNFT
 * @dev A contract for minting and managing Aureus NFTs with various traits and services
 */
contract AureusNFT is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    struct TokenTraits {
        uint256 grade;
        uint256 value;
        bool hasVaulting;
        bool hasInsurance;
        bool hasTransportation;
        uint256 administrationEndTimestamp;
        uint256 mintTimestamp;
        uint256 redeemTimestamp;
    }

    IShardNFT public shardContract;
    uint256 public constant SHARDS_REQUIRED = 5;
    uint256 public soulboundDays;
    mapping(uint256 => TokenTraits) public tokenTraits;
    
    uint256 public base_value = 500000; // 5000 GBP in pence

    AggregatorV3Interface public ethUsdPriceFeed;
    AggregatorV3Interface public gbpUsdPriceFeed;

    uint256 public update_price = 5000; // 50 GBP
    uint256 public vaulting_price = 5000; // 50 GBP
    uint256 public insurance_price = 5000; // 50 GBP
    uint256 public transportation_price = 5000; // 50 GBP
    uint256 public administration_price = 5000; // 50 GBP

    string public baseTokenURI;

    // Maximum number of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 10000;

    event ShardContractUpdated(address indexed newShardContract);
    event SoulboundDaysUpdated(uint256 newSoulboundDays);
    event TokenGraded(uint256 indexed tokenId, uint256 grade);
    event TokenBurned(address indexed from, uint256 tokenId);
    event TokenValueUpdated(uint256 indexed tokenId, uint256 newValue);
    event ServiceAdded(uint256 indexed tokenId, string service);
    

    /**
     * @dev Constructor to initialize the AureusNFT contract
     * @param _shardContract Address of the shard contract
     * @param _soulboundDays Number of days tokens remain soulbound
     * @param _baseTokenURI Base URI for token metadata
     */
    constructor(address _shardContract, uint256 _soulboundDays, string memory _baseTokenURI) ERC721("Aureus NFT", "ANFT") Ownable(msg.sender) {
        require(_shardContract != address(0), "Invalid shard contract address");
        shardContract = IShardNFT(_shardContract);
        soulboundDays = _soulboundDays;
        baseTokenURI = _baseTokenURI;
        ethUsdPriceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        gbpUsdPriceFeed = AggregatorV3Interface(0x91FAB41F5f3bE955963a986366edAcff1aaeaa83);
    }

    /**
     * @dev Mint a new Aureus NFT
     * @notice Requires the caller to have sufficient shard balance
     */
    function mintAureus() external nonReentrant whenNotPaused {
        require(_tokenIds.current() < MAX_SUPPLY, "Max supply reached");
        
        uint256 shardBalance = shardContract.balanceOf(msg.sender, 0);
        require(shardBalance >= SHARDS_REQUIRED, "Insufficient shard balance");
        
        uint256 newTokenId = _tokenIds.current();
        
        // Attempt to burn shards before minting
        try shardContract.burnShard(msg.sender, SHARDS_REQUIRED) {
            _tokenIds.increment();
            _safeMint(msg.sender, newTokenId);

            tokenTraits[newTokenId] = TokenTraits({
                grade: 0,
                value: base_value,
                hasVaulting: false,
                hasInsurance: false,
                hasTransportation: false,
                administrationEndTimestamp: 0,
                mintTimestamp: block.timestamp,
                redeemTimestamp: 0
            });
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Failed to burn shards: ", reason)));
        } catch {
            revert("Failed to burn shards: unknown error");
        }
    }

    function redeemShard(address account, uint256 tokenId) external nonReentrant whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");

        _burn(tokenId);
        tokenTraits[tokenId].redeemTimestamp = block.timestamp;

        emit TokenBurned(account, tokenId);
    }

    /**
     * @dev Set the base value for tokens
     * @param _base_value New base value in pence
     */
    function setValue(uint256 _base_value) external onlyOwner {
        base_value = _base_value;
    }

    /**
     * @dev Set prices for various services
     * @param _vaulting_price Price for vaulting service
     * @param _insurance_price Price for insurance service
     * @param _transportation_price Price for transportation service
     * @param _administration_price Price for administration service
     */
    function setPrice(uint256 _vaulting_price, uint256 _insurance_price, uint256 _transportation_price, uint256 _administration_price) external onlyOwner {
        vaulting_price = _vaulting_price;
        insurance_price = _insurance_price;
        transportation_price = _transportation_price;
        administration_price = _administration_price;
    }

    /**
     * @dev Convert GBP pence amount to ETH
     * @param penceAmount Amount in GBP pence
     * @return Equivalent amount in ETH (wei)
     */
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

    /**
     * @dev Upgrade a token's grade
     * @param tokenId ID of the token to upgrade
     */
    function upgradeToken(uint256 tokenId) external payable nonReentrant whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(tokenTraits[tokenId].grade < 70, "Invalid grade");

        uint256 priceInEth = getEthPrice(update_price);
        require(msg.value >= priceInEth, "Insufficient payment");
        
        if (tokenTraits[tokenId].grade == 0) {
            tokenTraits[tokenId].grade = 60;
        } else {
            tokenTraits[tokenId].grade++;
        }

        updateTokenValue(tokenId);
        emit TokenGraded(tokenId, tokenTraits[tokenId].grade);

        if(msg.value > priceInEth) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - priceInEth}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Update token value based on its traits
     * @param tokenId ID of the token to update
     */
    function updateTokenValue(uint256 tokenId) internal {
        TokenTraits storage traits = tokenTraits[tokenId];
        uint256 value = base_value;

        if (traits.grade >= 60) {
            value += value * 15 / 100; 
            if (traits.grade > 60 && traits.grade <= 67) {
                value += value * (traits.grade - 60) * 5 / 100; 
            } 
            if (traits.grade >= 68) {
                value += value * 6 / 100; 
            } 
            if (traits.grade >= 69) {
                value += value * 7 / 100; 
            } 
            if (traits.grade == 70) {
                value += value * 15 / 100; 
            }
        }

        if (traits.hasVaulting) {
            value += value * 15 / 1000; 
        } 
        if (traits.hasInsurance) {
            value += value * 15 / 1000; 
        } 
        if (traits.hasTransportation) {
            value += value * 5 / 1000; 
        } 
        if (traits.administrationEndTimestamp > block.timestamp) {
            value += value * 10 / 1000; 
        }

        traits.value = value;
        emit TokenValueUpdated(tokenId, value);
    }

    /**
     * @dev Get token traits
     * @param tokenId ID of the token
     * @return TokenTraits struct containing token traits
     */
    function getTokenTraits(uint256 tokenId) public view returns (TokenTraits memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokenTraits[tokenId];
    }

    /**
     * @dev Add a service to a token
     * @param tokenId ID of the token
     * @param serviceId ID of the service to add
     */
    function addService(uint256 tokenId, uint256 serviceId) external payable nonReentrant whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        TokenTraits storage traits = tokenTraits[tokenId];

        uint256 price;
        if (serviceId == 1) { // Vaulting
            require(!traits.hasVaulting, "Vaulting service already added");
            price = vaulting_price;
            traits.hasVaulting = true;
        } else if (serviceId == 2) { // Insurance
            require(!traits.hasInsurance, "Insurance service already added");
            price = insurance_price;
            traits.hasInsurance = true;
        } else if (serviceId == 3) { // Transportation
            require(!traits.hasTransportation, "Transportation service already added");
            price = transportation_price;
            traits.hasTransportation = true;
        } else if (serviceId == 4) { // Administration
            require(traits.administrationEndTimestamp < block.timestamp, "Administration service still active");
            price = administration_price;
            traits.administrationEndTimestamp = block.timestamp + 365 days; // 1 year
        } else {
            revert("Invalid service ID");
        }

        uint256 priceInEth = getEthPrice(price);
        require(msg.value >= priceInEth, "Insufficient payment");

        updateTokenValue(tokenId);
        emit ServiceAdded(tokenId, getServiceName(serviceId));

        if(msg.value > priceInEth) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - priceInEth}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Get service name by ID
     * @param serviceId ID of the service
     * @return Name of the service
     */
    function getServiceName(uint256 serviceId) public pure returns (string memory) {
        if (serviceId == 1) return "vaulting";
        if (serviceId == 2) return "insurance";
        if (serviceId == 3) return "transportation";
        if (serviceId == 4) return "administration";
        revert("Invalid service ID");
    }

    /**
     * @dev Set the shard contract address
     * @param _shardContract New shard contract address
     */
    function setShardContract(address _shardContract) external onlyOwner {
        require(_shardContract != address(0), "Invalid shard contract address");
        shardContract = IShardNFT(_shardContract);
        emit ShardContractUpdated(_shardContract);
    }

    /**
     * @dev Set the number of days tokens remain soulbound
     * @param _soulboundDays New soulbound days value
     */
    function setSoulboundDays(uint256 _soulboundDays) external onlyOwner {
        soulboundDays = _soulboundDays;
        emit SoulboundDaysUpdated(_soulboundDays);
    }

    /**
     * @dev Set the base token URI
     * @param _newBaseTokenURI New base token URI
     */
    function setBaseTokenURI(string memory _newBaseTokenURI) external onlyOwner {
        baseTokenURI = _newBaseTokenURI;
    }

    /**
     * @dev Check if a token is still soulbound
     * @param tokenId ID of the token to check
     */
    function _checkSoulboundStatus(uint256 tokenId) internal view {
        require(
            block.timestamp >= tokenTraits[tokenId].mintTimestamp + soulboundDays * 1 days,
            "Token is soulbound"
        );
    }

    /**
     * @dev Override transferFrom to check soulbound status
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        _checkSoulboundStatus(tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Override transferFrom to check soulbound status
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _checkSoulboundStatus(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Get token URI
     * @param tokenId ID of the token
     * @return Token URI string
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    /**
     * @dev Check if a token exists
     * @param tokenId ID of the token to check
     * @return bool indicating if the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraw contract balance
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Update Chainlink price feed addresses
     * @param _ethUsdPriceFeed New ETH/USD price feed address
     * @param _gbpUsdPriceFeed New GBP/USD price feed address
     */
    function updatePriceFeeds(address _ethUsdPriceFeed, address _gbpUsdPriceFeed) external onlyOwner {
        require(_ethUsdPriceFeed != address(0) && _gbpUsdPriceFeed != address(0), "Invalid address");
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        gbpUsdPriceFeed = AggregatorV3Interface(_gbpUsdPriceFeed);
    }

    /**
     * @dev Get current token supply
     * @return Current number of tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Emergency function to rescue ERC20 tokens sent to the contract by mistake
     * @param tokenAddress Address of the ERC20 token to rescue
     * @param to Address to send the rescued tokens to
     */
    function rescueERC20(address tokenAddress, address to) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to rescue");
        require(token.transfer(to, balance), "Token transfer failed");
    }

    /**
     * @dev Check and approve shards for spending
     */
    function checkAndApproveShards() external {
        uint256 allowance = IERC20(address(shardContract)).allowance(msg.sender, address(this));
        if (allowance < SHARDS_REQUIRED) {
            require(IERC20(address(shardContract)).approve(address(this), type(uint256).max), "Approval failed");
        }
    }

    /**
     * @dev Fallback function to receive Ether
     */
    receive() external payable {}

    /**
     * @dev Fallback function to receive Ether and data
     */
    fallback() external payable {}
}
