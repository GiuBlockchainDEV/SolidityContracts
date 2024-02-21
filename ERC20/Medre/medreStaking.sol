```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Importing staking interface and another unspecified interface.
import "./stakingInterface.sol";
import "./interface.sol";

// The MedreStaking contract combines staking functionality with token functionality, including pausing and burning tokens.
contract MedreStaking is ReentrancyGuard, Ownable {

    using Math for uint256; // Utilizes a Math library for arithmetic operations.
    using SafeERC20 for IERC20; // Utilizes a SafeERC20 library for safe token transfers.

    IERC20 public medreToken; // The ERC20 token used for staking.

    // Initializes the contract with the token address.
    constructor(IERC20 _medreToken) {
        medreToken = _medreToken;
    }
    
    uint256 public rewardsPool; // Total rewards available in the pool.
    uint256 public divisorPool = 1000000; // A divisor for calculating rewards distribution.
    event poolDeposit(address indexed user, uint256 amount); // Emitted when rewards are added to the pool.

    // Allows the owner to add rewards to the pool.
    function addRewardsToPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        medreToken.safeTransferFrom(msg.sender, address(this), amount); // Safely transfers tokens from the owner to the contract.
        rewardsPool += amount; // Increments the rewards pool.

        emit poolDeposit(msg.sender, amount); // Emits an event for the deposit.
    }

    // Struct to keep track of individual stakes.
    struct Stake {
        uint256 amount; // Amount staked.
        uint256 dividends; // Dividends earned.
        uint256 dividendsWithdrawn; // Dividends withdrawn.
        uint256 startTime; // When the stake was created.
        uint256 lastClaimTime; // Last time rewards were claimed.
        bool isWithdrawn; // Whether the stake has been withdrawn.
    }

    uint256 public TV; // Total Value - could represent total staked amount.
    uint256 public TVL; // Total Value Locked - could represent total value locked in staking.
    uint256 public TVE; // Total Value Earned - could represent total earnings from staking.
    
    // Events to signal staking activities.
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event PenaltyApplied(address indexed user, uint256 penaltyAmount);
    event RewardClaimed(address indexed user, uint256 earnedRewards);
    event RewardCompounded(address indexed user, uint256 earnedRewards);

    // Mappings to track staking information per user.
    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public totalStakes;
    mapping(address => uint256) public totalDeposited;
    mapping(address => uint256) public totalEarned;
    mapping(address => uint256) public totalWithdrawn;


    // Allows a user to stake tokens.
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(medreToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        medreToken.safeTransfer(address(this), _amount); // Transfers tokens to the contract for staking.
        
        Stake memory newStake = Stake({
            amount: _amount,
            dividends: 0,
            dividendsWithdrawn: 0,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp,
            isWithdrawn: false
        });

        TV += _amount;
        TVL += _amount;
        totalDeposited[msg.sender] += _amount;
        totalStakes[msg.sender] += 1;
        
        stakes[msg.sender].push(newStake); // Adds the new stake to the user's stakes.
        emit Staked(msg.sender, _amount); // Emits an event signaling the stake.
    }
    
    // Returns a user's stakes.
    function getStakes(address _user) public view returns (uint256[] memory amounts, uint256[] memory dividends, uint256[] memory dividendsWithdrawn, uint256[] memory startTimes, uint256[] memory lastClaimTimes, bool[] memory isWithdrawn) {
        uint256 stakeCount = stakes[_user].length;

        amounts = new uint256[](stakeCount);
        dividends = new uint256[](stakeCount);
        dividendsWithdrawn = new uint256[](stakeCount);
        startTimes = new uint256[](stakeCount);
        lastClaimTimes = new uint256[](stakeCount);
        isWithdrawn = new bool[](stakeCount);

        for (uint256 i = 0; i < stakeCount; i++) {
            Stake storage staked = stakes[_user

][i];
            amounts[i] = staked.amount;
            dividends[i] = staked.dividends;
            dividendsWithdrawn[i] = staked.dividendsWithdrawn;
            startTimes[i] = staked.startTime;
            lastClaimTimes[i] = staked.lastClaimTime;
            isWithdrawn[i] = staked.isWithdrawn;
        }
        
        return (amounts, dividends, dividendsWithdrawn, startTimes, lastClaimTimes, isWithdrawn); // Returns details of all stakes for a user.
    }

    // Allows a user to unstake tokens.
    function unstake(uint256 _stakeIndex) external nonReentrant returns (bool) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        require(!staked.isWithdrawn, "Already withdrawn");
        require(block.timestamp >= staked.startTime + LOCK_PERIOD, "Stake is locked");
        
        (uint256 _stakedAmount, uint256 _penaltyAmount, uint256 _rewardAmount) = calculateReward(_stakeIndex, 0);

        staked.dividendsWithdrawn += _rewardAmount;
        staked.lastClaimTime = block.timestamp;
        staked.isWithdrawn = true;
        
        medreToken.safeTransfer(msg.sender, _stakedAmount + _rewardAmount); // Transfers the staked amount and rewards back to the user.
        emit Unstaked(msg.sender, _stakedAmount, _rewardAmount); // Emits an event signaling the unstake.

        TVL -= _stakedAmount;
        TVE += _rewardAmount;
        totalDeposited[msg.sender] -= _stakedAmount;

        // Apply penalties if any
        applyPenalties(_penaltyAmount);
        
        return (true);
    }

    // Allows a user to compound their dividends.
    function compoundDividends(uint256 _stakeIndex) public nonReentrant returns (bool) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        require(!staked.isWithdrawn, "Already withdrawn");
        require(block.timestamp >= staked.startTime + LOCK_PERIOD, "Staking period not yet over");
        require(block.timestamp >= staked.lastClaimTime + LOCK_PERIOD, "Compound period not yet over");

        (, uint256 _penaltyAmount, uint256 _rewardAmount) = calculateReward(_stakeIndex, 2);
        staked.amount += _rewardAmount;
        staked.lastClaimTime = block.timestamp;

        totalEarned[msg.sender] += _rewardAmount;
        TV += _rewardAmount;
        TVL += _rewardAmount;
        totalDeposited[msg.sender] += _rewardAmount;
        emit RewardCompounded(msg.sender, _rewardAmount); // Emits an event signaling the compounding of rewards.

        // Apply penalties if any
        applyPenalties(_penaltyAmount);
        
        return (true);
    }

    // Allows a user to claim their rewards.
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

        // Calculate earned rewards based on remaining time
        totalEarned[msg.sender] += _rewardAmount;
        totalWithdrawn[msg.sender] += _rewardAmount;
        TVE += _rewardAmount;
        medreToken.safeTransfer(msg.sender, _rewardAmount); // Transfers the rewards to the user.
        emit RewardClaimed(msg.sender, _rewardAmount); // Emits an event signaling the claiming of rewards.

        staked.lastClaimTime = block.timestamp;
        staked.dividends = 0;
        staked.dividendsWithdrawn = _rewardAmount;

        // Apply penalties if any
        applyPenalties(_penaltyAmount);

        return (true);
    }

    // Calculates the dividends ratio based on the rewards pool and total value locked.
    function dividendsRatio() public view returns (uint256 _dividendsRatio) {
        _dividendsRatio = rewardsPool * divisorPool / TVL / 365;
    }

    // Calculates the reward for a given stake index and type

 (unstake, claim, compound).
    function calculateReward(uint256 _stakeIndex, uint256 _type) public view returns (uint256 _stakedAmount, uint256 _penaltyAmount, uint256 _rewardAmount) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        uint256 ratio = dividendsRatio();
        uint256 dayPassed = daysPassedSince(staked.lastClaimTime);
        _stakedAmount = staked.amount;
        _rewardAmount = staked.amount * ratio * dayPassed / divisorPool;

        // Type 0 -> Unstake
        // Type 1 -> Claim
        // Type 2 -> Compound
        
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
            return (0, 0, 0);
        }
        return (_stakedAmount, _penaltyAmount, _rewardAmount); // Returns the staked amount, any penalty applied, and the final reward amount.
    }

    
    uint256 public afterYearPenalty = 40; // Penalty for unstaking after a year from the start time.
    uint256 public afterGracePenalty = 10; // Penalty for actions taken after the grace period.
    uint256 public burnedFraction = 50; // Fraction of penalties that get burned.
    uint256 public dividendFraction = 50; // Fraction of penalties that go back into the rewards pool.
    uint256 public divisor = 100; // Divisor for calculating fractions.

    // Applies penalties to the penalties amount and adjusts the rewards pool accordingly.
    function applyPenalties(uint256 _penaltyAmount) internal {
        if(_penaltyAmount > 0) {
            uint256 _poolAmount = _penaltyAmount * dividendFraction / divisor; // Calculates the amount to add back to the rewards pool.
            rewardsPool += _poolAmount; // Adds to the rewards pool.
            // Burn the rest of the penalty amount.
            uint256 _burnedAmount = _penaltyAmount - _poolAmount;
            medreToken.safeTransfer(address(0), _burnedAmount); // Burns the calculated amount.
            emit PenaltyApplied(msg.sender, _penaltyAmount); // Emits an event signaling the application of a penalty.
        }
    }

    // TIME

    uint256 public constant LOCK_PERIOD = 365 days; // The period for which stakes are locked.
    uint256 public constant GRACE_PERIOD = 30 days; // Grace period after the lock period ends.
    uint256 public constant CYCLE_PERIOD = LOCK_PERIOD + GRACE_PERIOD; // Total cycle period including lock and grace periods.

    // Calculates the number of days passed since a given timestamp.
    function daysPassedSince(uint256 pastTimestamp) public view returns (uint256) {
        require(block.timestamp > pastTimestamp, "Timestamp is in the future");
        return (block.timestamp - pastTimestamp) / 60 / 60 / 24;
    }

    // Calculates the number of cycles passed since a given timestamp.
    function cyclesPassedSince(uint256 pastTimestamp) public view returns (uint256) {
        require(block.timestamp > pastTimestamp, "Timestamp is in the future");
        uint256 timeDifference = block.timestamp - pastTimestamp;
        uint256 cyclesPassed = timeDifference / CYCLE_PERIOD;
        return cyclesPassed;
    }

    // Checks if the current time is within the grace period of a cycle.
    function isWithinGracePeriod(uint256 startTime, uint256 currentTime) public pure returns (bool) {
        uint256 timeSinceStart = currentTime - startTime;
        uint256 timeSinceCycleStart = timeSinceStart % CYCLE_PERIOD;
        return timeSinceCycleStart > LOCK_PERIOD && timeSinceCycleStart <= CYCLE_PERIOD;
    }

    // Checks if a deposit is within the grace period and returns the number of days passed.
    function isWithinGracePeriodDeposit(uint256 _stakeIndex) public view returns (bool, uint256) {
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        uint256 timeSinceStart = block.timestamp - staked.startTime;
        uint256 timeSinceCycleStart = timeSinceStart % CYCLE_PERIOD;
        uint256 dayPassed = cyclesPassedSince(staked.startTime);
        return (timeSinceCycleStart > LOCK_PERIOD && timeSinceCycleStart <= CYCLE_PERIOD, dayPassed);
    }
}
```
