// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./stakingInterface.sol";
import "./interface.sol";

contract MedreStaking is ReentrancyGuard, Ownable {

    using Math for uint256;
    using SafeERC20 for IERC20;

    IERC20 public medreToken;

    constructor(IERC20 _medreToken) {
        medreToken = _medreToken;
    }
    
    uint256 public rewardsPool;
    uint256 public divisorPool = 1000000;
    event poolDeposit(address indexed user, uint256 amount);

    function addRewardsToPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        medreToken.safeTransferFrom(msg.sender, address(this), amount);
        rewardsPool += amount;

        emit poolDeposit(msg.sender, amount);
    }

    struct Stake {
        uint256 amount;
        uint256 dividends;
        uint256 dividendsWithdrawn;
        uint256 startTime;
        uint256 lastClaimTime;
        bool isWithdrawn;
    }

    uint256 public TV;
    uint256 public TVL;
    uint256 public TVE;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event PenaltyApplied(address indexed user, uint256 penaltyAmount);
    event RewardClaimed(address indexed user, uint256 earnedRewards);
    event RewardCompounded(address indexed user, uint256 earnedRewards);

    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public totalStakes;
    mapping(address => uint256) public totalDeposited;
    mapping(address => uint256) public totalEarned;
    mapping(address => uint256) public totalWithdrawn;


    // STAKE 
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(medreToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        medreToken.safeTransfer(address(this), _amount);
        
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
        
        stakes[msg.sender].push(newStake);
        emit Staked(msg.sender, _amount);
    }
    
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

    // UNSTAKE 
    function unstake(uint256 _stakeIndex) external nonReentrant returns (bool) {
        require(_stakeIndex < totalStakes[msg.sender], "Invalid stake index");
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        require(!staked.isWithdrawn, "Already withdrawn");
        require(block.timestamp >= staked.startTime + LOCK_PERIOD, "Stake is locked");
        
        (uint256 _stakedAmount, uint256 _penaltyAmount, uint256 _rewardAmount) = calculateReward(_stakeIndex, 0);

        staked.dividendsWithdrawn += _rewardAmount;
        staked.lastClaimTime = block.timestamp;
        staked.isWithdrawn = true;
        
        medreToken.safeTransfer(msg.sender, _stakedAmount + _rewardAmount);
        emit Unstaked(msg.sender, _stakedAmount, _rewardAmount);

        TVL -= _stakedAmount;
        TVE += _rewardAmount;
        totalDeposited[msg.sender] -= _stakedAmount;

        // Apply penalties if any
        applyPenalties(_penaltyAmount);
        
        return (true);
    }

    // COMPOUND 
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
        emit RewardCompounded(msg.sender, _rewardAmount);

        // Apply penalties if any
        applyPenalties(_penaltyAmount);
        
        return (true);
    }

    // CLAIM 
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
        medreToken.safeTransfer(msg.sender, _rewardAmount);
        emit RewardClaimed(msg.sender, _rewardAmount);

        staked.lastClaimTime = block.timestamp;
        staked.dividends = 0;
        staked.dividendsWithdrawn = _rewardAmount;

        // Apply penalties if any
        applyPenalties(_penaltyAmount);

        return (true);
    }

    function dividendsRatio() public view returns (uint256 _dividendsRatio) {
        _dividendsRatio = rewardsPool * divisorPool / TVL / 365;
    }

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
        return (_stakedAmount, _penaltyAmount, _rewardAmount); // Placeholder
    }

    
    uint256 public afterYearPenalty = 40;
    uint256 public afterGracePenalty = 10;
    uint256 public burnedFraction = 50;
    uint256 public dividendFraction = 50;
    uint256 public divisor = 100;

    // Helper function to apply penalties and adjust rewards pool
    function applyPenalties(uint256 _penaltyAmount) internal {
        if(_penaltyAmount > 0) {
            uint256 _poolAmount = _penaltyAmount * dividendFraction / divisor;
            rewardsPool += _poolAmount;
            // Burn the rest of the penalty amount
            uint256 _burnedAmount = _penaltyAmount - _poolAmount;
            medreToken.safeTransfer(address(0), _burnedAmount);
            emit PenaltyApplied(msg.sender, _penaltyAmount);
        }
    }

    // TIME

    uint256 public constant LOCK_PERIOD = 365 days;
    uint256 public constant GRACE_PERIOD = 30 days;
    uint256 public constant CYCLE_PERIOD = LOCK_PERIOD + GRACE_PERIOD;

    function daysPassedSince(uint256 pastTimestamp) public view returns (uint256) {
        require(block.timestamp > pastTimestamp, "Timestamp is in the future");
        return (block.timestamp - pastTimestamp) / 60 / 60 / 24;
    }

    function cyclesPassedSince(uint256 pastTimestamp) public view returns (uint256) {
        require(block.timestamp > pastTimestamp, "Timestamp is in the future");
        uint256 timeDifference = block.timestamp - pastTimestamp;
        uint256 cyclesPassed = timeDifference / CYCLE_PERIOD;
        return cyclesPassed;
    }

    function isWithinGracePeriod(uint256 startTime, uint256 currentTime) public pure returns (bool) {
        uint256 timeSinceStart = currentTime - startTime;
        uint256 timeSinceCycleStart = timeSinceStart % CYCLE_PERIOD;
        return timeSinceCycleStart > LOCK_PERIOD && timeSinceCycleStart <= CYCLE_PERIOD;
    }

    function isWithinGracePeriodDeposit(uint256 _stakeIndex) public view returns (bool, uint256) {
        Stake storage staked = stakes[msg.sender][_stakeIndex];
        uint256 timeSinceStart = block.timestamp - staked.startTime;
        uint256 timeSinceCycleStart = timeSinceStart % CYCLE_PERIOD;
        uint256 dayPassed = cyclesPassedSince(staked.startTime);
        return (timeSinceCycleStart > LOCK_PERIOD && timeSinceCycleStart <= CYCLE_PERIOD, dayPassed);
    }
}


