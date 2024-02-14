// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Import the staking interface and the token contract
import "./stakingInterface.sol";
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
    
    uint256 public rewardsPool; // Total rewards available in the pool
    uint256 public divisorPool = 1000000; // Divisor to calculate rewards distribution
    event poolDeposit(address indexed user, uint256 amount); // Event for tracking rewards pool deposits

    // Allows the owner to add rewards to the pool
    function addRewardsToPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        transferFrom(msg.sender, address(this), amount); // Transfer tokens to the contract
        rewardsPool += amount; // Increase the rewards pool

        emit poolDeposit(msg.sender, amount); // Emit an event for the deposit
    }

    // Structure to represent a stake
    struct Stake {
        uint256 amount; // Amount of tokens staked
        uint256 dividends; // Dividends earned
        uint256 dividendsWithdrawn; // Dividends that have been withdrawn
        uint256 startTime; // When the stake was created
        uint256 lastClaimTime; // Last time rewards were claimed
        bool isWithdrawn; // If the stake has been withdrawn
    }

    uint256 public totalVolume; // Total volume
    uint256 public totalValueLocked; // Total value locked in the contract
    uint256 public totalValueEarned; // Total value earned 
    
    // Events for tracking staking actions
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event PenaltyApplied(address indexed user, uint256 penaltyAmount);
    event RewardClaimed(address indexed user, uint256 earnedRewards);
    event RewardCompounded(address indexed user, uint256 earnedRewards);

    // Mappings to track user stakes and totals
    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public totalStakes;
    mapping(address => uint256) public totalDeposited;
    mapping(address => uint256) public totalEarned;
    mapping(address => uint256) public totalWithdrawn;

    // Allows a user to stake tokens
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        transfer(address(this), _amount); // Transfer tokens to the contract
        
        // Create a new stake
        Stake memory newStake = Stake({
            amount: _amount,
            dividends: 0,
            dividendsWithdrawn: 0,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            isWithdrawn: false
        });

        totalVolume += _amount;
        totalValueLocked += _amount; // Increase total value locked
        totalDeposited[msg.sender] += _amount; // Track the user's total deposited amount
        totalStakes[msg.sender] += 1; // Increment the user's stake count
        
        stakes[msg.sender].push(newStake); // Add the new stake to the user's stakes
        emit Staked(msg.sender, _amount); // Emit a staking event
    }
    
    // Returns the stakes for a given user
    function getStakes(address _user) public view returns (uint256[] memory amounts, uint256[] memory dividends, uint256[] memory dividendsWithdrawn, uint256[] memory startTimes, uint256[] memory lastClaimTimes, bool[] memory isWithdrawn) {
        uint256 stakeCount = stakes[_user].length;

        amounts = new uint256[](stakeCount);
        dividends = new uint256[](stakeCount);
        dividendsWithdrawn = new uint256[](stakeCount);
        startTimes = new uint256[](stakeCount);
        lastClaimTimes = new uint256[](stakeCount);
        isWithdrawn = new bool[](stakeCount);

        for (uint256 i = 0; i < stakeCount; i++) {
            Stake storage staked = stakes[_user][i];
            amounts[i] = staked.amount;
            dividends[i] = staked.dividends;
            dividendsWithdrawn[i] = staked.dividendsWithdrawn;
            startTimes[i] = staked.startTime;
            lastClaimTimes[i] = staked.lastClaimTime;
            isWithdrawn[i] = staked.isWithdrawn;
        }
        
        return (amounts, dividends, dividendsWithdrawn, startTimes, lastClaimTimes, isWithdrawn);
    }

    // Unstakes a given stake, returns tokens and rewards to the user
    function unstake(uint256 _stakeIndex) external nonReentrant returns (bool) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        require(!staked.isWithdrawn, "Already withdrawn");
        require(block.timestamp >= staked.startTime + LOCK_PERIOD, "Stake is locked");
        
        (uint256 _stakedAmount, uint256 _penaltyAmount, uint256 _rewardAmount) = calculateReward(_stakeIndex, 0);
        
        require(balanceOf(address(this)) >= _stakedAmount + _rewardAmount, "Insufficient balance");
        // Apply penalties if any
        applyPenalties(_penaltyAmount);

        staked.dividendsWithdrawn += _rewardAmount;
        staked.lastClaimTime = block.timestamp;
        staked.isWithdrawn = true;

        transferFrom(address(this), msg.sender, _stakedAmount + _rewardAmount); // Return staked amount and rewards
        emit Unstaked(msg.sender, _stakedAmount, _rewardAmount); // Emit an unstaking event

        totalValueLocked -= _stakedAmount; // Decrease total value locked
        totalValueEarned += _rewardAmount; // Increase total value earned (not used in provided code)
        totalDeposited[msg.sender] -= _stakedAmount; // Adjust user's total deposited amount
        
        return true; // Indicate successful unstaking
    }

    // Allows a user to compound their dividends back into the stake
    function compoundDividends(uint256 _stakeIndex) public nonReentrant returns (bool) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        require(!staked.isWithdrawn, "Already withdrawn");
        require(block.timestamp >= staked.startTime + LOCK_PERIOD, "Staking period not yet over");
        require(block.timestamp >= staked.lastClaimTime + LOCK_PERIOD, "Compound period not yet over");

        (, uint256 _penaltyAmount, uint256 _rewardAmount) = calculateReward(_stakeIndex, 2);

        // Apply penalties if any
        applyPenalties(_penaltyAmount);

        staked.amount += _rewardAmount; // Compound the rewards into the stake
        staked.lastClaimTime = block.timestamp;

        totalEarned[msg.sender] += _rewardAmount; // Update user's total earned rewards
        totalVolume += _rewardAmount; // Increase total value staked (not used in provided code)
        totalValueLocked += _rewardAmount; // Increase total value locked
        totalDeposited[msg.sender] += _rewardAmount; // Update user's total deposited amount
        emit RewardCompounded(msg.sender, _rewardAmount); // Emit a compounding event

        return true; // Indicate successful compounding
    }

    // Allows a user to claim their earned rewards
    function claimRewards(uint256 _stakeIndex) public returns (bool) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        require(!staked.isWithdrawn, "Already withdrawn");
        require(block.timestamp >= staked.startTime + LOCK_PERIOD, "Staking period not yet over");
        require(isWithinGracePeriod(staked.startTime, block.timestamp), "Out of grace period");
        require(block.timestamp >= staked.lastClaimTime + LOCK_PERIOD, "Claim period not yet over");

        // Calculate total rewards earned
        (, uint256 _penaltyAmount, uint256 rewardAmount) = calculateReward(_stakeIndex, 1);
        uint256 _rewardAmount = rewardAmount;

        require(balanceOf(address(this)) >= _rewardAmount, "Insufficient balance");
        // Apply penalties if any
        applyPenalties(_penaltyAmount);

        // Calculate earned rewards based on remaining time
        totalEarned[msg.sender] += _rewardAmount;
        totalWithdrawn[msg.sender] += _rewardAmount;
        totalValueEarned += _rewardAmount; // Increase total value earned (not used in provided code)
        transferFrom(address(this), msg.sender, _rewardAmount); // Transfer earned rewards to the user
        emit RewardClaimed(msg.sender, _rewardAmount); // Emit a reward claim event

        staked.lastClaimTime = block.timestamp;
        staked.dividends = 0;
        staked.dividendsWithdrawn = _rewardAmount;

        return true; // Indicate successful reward claim
    }

    // Calculates the dividends ratio based on the rewards pool and total value locked
    function dividendsRatio() public view returns (uint256 _dividendsRatio) {
        _dividendsRatio = rewardsPool * divisorPool / totalValueLocked / 365;
    }

    // Calculates rewards, penalties, and returns the staked amount, penalty amount, and reward amount
    function calculateReward(uint256 _stakeIndex, uint256 _type) public view returns (uint256 _stakedAmount, uint256 _penaltyAmount, uint256 _rewardAmount) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        uint256 ratio = dividendsRatio();
        uint256 dayPassed = daysPassedSince(staked.lastClaimTime);
        _stakedAmount = staked.amount;
        _rewardAmount = staked.amount * ratio * dayPassed / divisorPool;

        // Type 0 -> Unstake, Type 1 -> Claim, Type 2 -> Compound
        // Apply penalties based on the type of action and whether it's within the grace period
        if (block.timestamp >= staked.startTime + LOCK_PERIOD) {
            if (!isWithinGracePeriod(staked.startTime, block.timestamp)) {

                if (_type == 0) {
                    _penaltyAmount = _rewardAmount * afterYearPenalty / divisor;
                } else {
                    _penaltyAmount = _rewardAmount * afterGracePenalty / divisor;
                }
                _rewardAmount -= _penaltyAmount;
            } 
        } else {
            return (0, 0, 0); // No rewards if the stake is not yet mature
        }
        return (_stakedAmount, _penaltyAmount, _rewardAmount); // Return calculated values
    }

    // Penalty rates and fractions for calculating penalties and rewards distribution
    uint256 public afterYearPenalty = 40;
    uint256 public afterGracePenalty = 10;
    uint256 public burnedFraction = 50;
    uint256 public dividendFraction = 50;
    uint256 public divisor = 100;

    // Internal function to apply penalties and adjust the rewards pool
    function applyPenalties(uint256 _penaltyAmount) internal {
        if(_penaltyAmount > 0) {
            uint256 _poolAmount = _penaltyAmount * dividendFraction / divisor; // Calculate amount to add to the rewards pool
            rewardsPool += _poolAmount; // Increase rewards pool
            // Burn the rest of the penalty amount
            uint256 _burnedAmount = _penaltyAmount - _poolAmount;

            require(balanceOf(address(this)) >= _burnedAmount, "Insufficient balance");
            transferFrom(address(this), address(0), _burnedAmount); // Burn tokens
            emit PenaltyApplied(msg.sender, _penaltyAmount); // Emit a penalty event
        }
    }

    // Time-related constants and functions
    uint256 public constant LOCK_PERIOD = 365 days; // Lock period for staking
    uint256 public constant GRACE_PERIOD = 30 days; // Grace period following the lock period
    uint256 public constant CYCLE_PERIOD = LOCK_PERIOD + GRACE_PERIOD; // Total cycle period including lock and grace periods

    // Calculates the number of days passed since a given timestamp
    function daysPassedSince(uint256 pastTimestamp) public view returns (uint256) {
        require(block.timestamp > pastTimestamp, "Timestamp is in the future");
        return (block.timestamp - pastTimestamp) / 60 / 60 / 24;
    }

    // Calculates the number of cycles passed since a given timestamp
    function cyclesPassedSince(uint256 pastTimestamp) public view returns (uint256) {
        require(block.timestamp > pastTimestamp, "Timestamp is in the future");
        uint256 timeDifference = block.timestamp - pastTimestamp;
        uint256 cyclesPassed = timeDifference / CYCLE_PERIOD;
        return cyclesPassed;
    }

    // Checks if the current time is within the grace period
    function isWithinGracePeriod(uint256 startTime, uint256 currentTime) public pure returns (bool) {
        uint256 timeSinceStart = currentTime - startTime;
        uint256 timeSinceCycleStart = timeSinceStart % CYCLE_PERIOD;
        return timeSinceCycleStart > LOCK_PERIOD && timeSinceCycleStart <= CYCLE_PERIOD;
    }

    // Determines if a deposit is within the grace period and returns the number of days passed
    function isWithinGracePeriodDeposit(uint256 _stakeIndex) public view returns (bool, uint256) {
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        uint256 timeSinceStart = block.timestamp - staked.startTime;
        uint256 timeSinceCycleStart = timeSinceStart % CYCLE_PERIOD;
        uint256 dayPassed = cyclesPassedSince(staked.startTime);
        return (timeSinceCycleStart > LOCK_PERIOD && timeSinceCycleStart <= CYCLE_PERIOD, dayPassed);
    }
}
