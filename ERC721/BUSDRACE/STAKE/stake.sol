// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./contract.sol";
import "./library.sol";

contract NFTStaking is ERC721A__IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct boostInfo{
        bool boosted;
        uint256 boostId;}

    struct stakingInfo {
        bool staked;
        uint256 tokenValue;
        uint256 valueWithdrawn;
        uint256 stakingTimestamp;
        bool boosted;
        uint256 stakingBoostTimestamp;}
    
    mapping(address => boostInfo) public boostData;
    mapping(address => mapping(address => mapping(uint256 => stakingInfo))) public stakingData;
    mapping(address => address[]) public addedContracts;
    mapping(address => mapping (address => uint256[])) public ownedTokens;

    //Wallet for tax

    address public devWallet;

    function setAddress(address _devWallet) external onlyOwner {
        devWallet = _devWallet;}

    //Moderator

    address public moderator;

    modifier onlyModerator() {
        require(msg.sender == owner() || msg.sender == moderator, "Not owner or moderator!");
        _;}

    function setModerator(address _moderator) external onlyOwner {
        moderator = _moderator;}

    //Contract Allowance

    address[] public allowedContracts;

    modifier onlyAllowedContracts() {
        bool isAllowed = false;
        for (uint i = 0; i < allowedContracts.length; i++) {
            if (msg.sender == allowedContracts[i]) {
                isAllowed = true;
                break;}}
        require(isAllowed, "Caller address not allowed!");
        _;}

    function addAllowedContract(address _contractAddress) public onlyOwner {
        allowedContracts.push(_contractAddress);}

    function removeAllowedContract(address _contractAddress) public onlyOwner {
        for (uint256 i = 0; i < allowedContracts.length; i++) {
            if (allowedContracts[i] == _contractAddress) {
                allowedContracts[i] = allowedContracts[allowedContracts.length - 1];
                allowedContracts.pop();
                break;}}}

    function checkContractAllowed(address _contractAddress) public view returns (bool) {
        bool isAllowed = false;
        for (uint256 i = 0; i < allowedContracts.length; i++) {
            if (allowedContracts[i] == _contractAddress) {
                isAllowed = true;
                break;}}
        return isAllowed;}

    function isContractAdded(address _user, address _contractAddress) internal view returns(bool) {
        address[] memory contracts = addedContracts[_user];
        for(uint i = 0; i < contracts.length; i++) {
            if(contracts[i] == _contractAddress) {
                return true;}}
        return false;}

    function isTokenIdAdded(address _user, address _contractAddress, uint256 _tokenId) internal view returns(bool) {
        uint256[] memory tokens = ownedTokens[_user][_contractAddress];
        for(uint i = 0; i < tokens.length; i++) {
            if(tokens[i] == _tokenId) {
                return true;}}
        return false;}

    //Staking 
    uint256 public totalValueLocked;
    uint256 public totalNFTLocked;
    //getTotalValueLocked() e getTotalNFTLocked() 

    function stakeNFT(address _caller, address _collection, uint256 tokenId, uint256 _nominalValue) external onlyAllowedContracts returns (bool) {
        require(addToken(_caller, _collection, tokenId, _nominalValue), "ID not added");
        return true;}

    function addToken(address _caller, address _contractAddress, uint256 _tokenId, uint256 _value) internal returns (bool) {
        require(!isTokenIdAdded(_caller, _contractAddress, _tokenId), "TokenId already added for this contract.");
        if(!isContractAdded(_caller, _contractAddress)) {
            addedContracts[_caller].push(_contractAddress);}
        stakingData[_caller][_contractAddress][_tokenId].staked = true;
        stakingData[_caller][_contractAddress][_tokenId].tokenValue = _value;
        stakingData[_caller][_contractAddress][_tokenId].stakingTimestamp = block.timestamp;
        ownedTokens[_caller][_contractAddress].push(_tokenId);
        totalValueLocked = totalValueLocked + _value;
        totalNFTLocked = totalNFTLocked + 1;
        return true;}
        
    function getValueWithdrable(address _collection, uint256 _tokenId) public view returns (uint256) {
        uint256 _nominalValue = stakingData[msg.sender][_collection][_tokenId].tokenValue;
        uint256 _halfNominalValue = _nominalValue.mul(50).div(100);
        uint256 _valueWhitdrawn = stakingData[msg.sender][_collection][_tokenId].valueWithdrawn;
        uint256 _amount = 0;
        if(_valueWhitdrawn > _halfNominalValue){
            _amount = _nominalValue - _valueWhitdrawn;}
        else{
            _amount = _halfNominalValue;}
        return _amount;}

    function unstakeNFT(address _collection, uint256 _tokenId) external {
        IERC721A _nftCollection = IERC721A(_collection);
        require(stakingData[msg.sender][_collection][_tokenId].staked, "Token not staked");
        uint256 amountWhitdrable = getValueWithdrable(_collection, _tokenId);
        require(amountWhitdrable > 0, "No tokens to claim!");
        require(paymentToken.transfer(msg.sender, amountWhitdrable.mul(90).div(100)) && paymentToken.transfer(devWallet, amountWhitdrable.mul(10).div(100)) , "Token transfer failed!");
        require(removeToken(_collection, _tokenId), "ID not removed");
        _nftCollection.safeTransferFrom(address(this), msg.sender, _tokenId);}

    function removeToken(address _contractAddress, uint256 _tokenId) internal returns (bool) {
        // Verifica che il token sia effettivamente in staking prima di rimuoverlo
        require(stakingData[msg.sender][_contractAddress][_tokenId].staked, "Token not staked");
        totalValueLocked = totalValueLocked - stakingData[msg.sender][_contractAddress][_tokenId].tokenValue;
        totalNFTLocked = totalNFTLocked - 1;
        stakingData[msg.sender][_contractAddress][_tokenId].staked = false;
        stakingData[msg.sender][_contractAddress][_tokenId].tokenValue = 0;
        stakingData[msg.sender][_contractAddress][_tokenId].stakingTimestamp = 0;
        
        return true;}

    //NOS

    IERC721A public nosNFT;

    function checkBoost() public view returns (bool, uint256) {
        return (boostData[msg.sender].boosted, boostData[msg.sender].boostId);}

    function setNosNFT(address _nosNFT) external onlyOwner {
        nosNFT = IERC721A(_nosNFT);}

    function activeBoost(uint256 _tokenId) external {
        require(boostData[msg.sender].boosted = false, "Boost already staked");
        nosNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        boostData[msg.sender].boosted = true;
        boostData[msg.sender].boostId = _tokenId;
        for (uint i = 0; i < allowedContracts.length; i++) {
            uint256[] memory tokens = ownedTokens[msg.sender][allowedContracts[i]];
            for(uint e = 0; i < tokens.length; i++) {
                if(stakingData[msg.sender][allowedContracts[i]][e].stakingBoostTimestamp == 0){
                    stakingData[msg.sender][allowedContracts[i]][e].stakingBoostTimestamp = block.timestamp;}}}}

    function disactiveBoost(uint256 _tokenId) external {
        require(boostData[msg.sender].boosted = true, "Boost not staked");
        nosNFT.safeTransferFrom(address(this), msg.sender, _tokenId);
        boostData[msg.sender].boosted = false;
        boostData[msg.sender].boostId = 0;
        for (uint i = 0; i < allowedContracts.length; i++) {
            uint256[] memory tokens = ownedTokens[msg.sender][allowedContracts[i]];
            for(uint e = 0; i < tokens.length; i++) {
                stakingData[msg.sender][allowedContracts[i]][e].stakingBoostTimestamp = 0;}}}
    
    function updateBoost() external {
        require(boostData[msg.sender].boosted = true, "Boost not staked");
        for (uint i = 0; i < allowedContracts.length; i++) {
            uint256[] memory tokens = ownedTokens[msg.sender][allowedContracts[i]];
            for(uint e = 0; i < tokens.length; i++) {
                if(stakingData[msg.sender][allowedContracts[i]][e].stakingBoostTimestamp == 0){
                    stakingData[msg.sender][allowedContracts[i]][e].stakingBoostTimestamp = block.timestamp;}}}}

    function getOwnedTokens(address _wallet, address _contractAddress) public view returns (uint256[] memory) {
        return ownedTokens[_wallet][_contractAddress];}

    IERC20 public paymentToken;

    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = IERC20(_paymentToken);}

    //Claim & Compound Rewards

    uint256 public rewardsPerMinutes = 1736;
    uint256 public additionalRewards = 694;
    uint256 public divisor = 100000000;

    function compound(address _contractAddress, uint256 _tokenId) external nonReentrant returns (bool) {
        require(stakingData[msg.sender][_contractAddress][_tokenId].staked, "NFT not staked");
        uint256 _nominalValue = stakingData[msg.sender][_contractAddress][_tokenId].tokenValue;
        uint256 nftStaked = stakingData[msg.sender][_contractAddress][_tokenId].stakingTimestamp;
        uint256 _valueCompund = getAccumulation(_nominalValue, nftStaked, rewardsPerMinutes);
        bool nosStaked = stakingData[msg.sender][_contractAddress][_tokenId].boosted;
        uint256 nosTimestamp = stakingData[msg.sender][_contractAddress][_tokenId].stakingBoostTimestamp;
        uint256 _valueCompundByNos = 0;
        if(nosStaked == true){
            _valueCompundByNos = getAccumulation(_nominalValue, nosTimestamp, additionalRewards);}
        totalValueLocked = totalValueLocked + _valueCompund + _valueCompundByNos;
        stakingData[msg.sender][_contractAddress][_tokenId].tokenValue = _nominalValue + _valueCompund + _valueCompundByNos;
        stakingData[msg.sender][_contractAddress][_tokenId].stakingTimestamp = block.timestamp;
        if(nosStaked == true){
            stakingData[msg.sender][_contractAddress][_tokenId].stakingBoostTimestamp = block.timestamp;}
        return true;}

    function getMinuteElapsed(uint256 _stakingTimestamp) internal view returns (uint256) {
        uint256 _minutesElapsed = (block.timestamp - _stakingTimestamp).div(60);
        return _minutesElapsed;}

    function getAccumulatedPercentage(uint256 _stakingTimestamp, uint256 _rewardsPerMinutes) internal view returns (uint256) {
        uint256 _minutesElapsed = getMinuteElapsed(_stakingTimestamp);
        uint256 _accumulatedPercentage = _minutesElapsed.mul(_rewardsPerMinutes);
        return _accumulatedPercentage;}

    function getAccumulation(uint256 _value, uint256 _stakingTimestamp, uint256 _rewardsPerMinutes) internal view returns (uint256) {
        uint256 _accumulatedPercentage = getAccumulatedPercentage(_stakingTimestamp, _rewardsPerMinutes);
        uint256 _accumulation = _value.mul(_accumulatedPercentage).div(divisor);
        return _accumulation;}

    function getTotalAccumulation(address _contractAddress, uint256 _tokenId) public view returns (uint256) {
        require(stakingData[msg.sender][_contractAddress][_tokenId].staked, "NFT not staked");
        uint256 _value = getAccumulation(stakingData[msg.sender][_contractAddress][_tokenId].tokenValue, stakingData[msg.sender][_contractAddress][_tokenId].stakingTimestamp, rewardsPerMinutes);
        if(stakingData[msg.sender][_contractAddress][_tokenId].boosted == true){
            _value = _value + getAccumulation(stakingData[msg.sender][_contractAddress][_tokenId].tokenValue, stakingData[msg.sender][_contractAddress][_tokenId].stakingBoostTimestamp, additionalRewards);}        
        return _value;}

    function claimRewards(address _contractAddress, uint256 _tokenId) external nonReentrant {
        uint256 _valueWhitdrawn = stakingData[msg.sender][_contractAddress][_tokenId].valueWithdrawn;
        uint256 _amount = getTotalAccumulation(_contractAddress, _tokenId);
        require(_amount > 0, "No tokens to claim!");
        require(paymentToken.transfer(msg.sender, _amount.mul(90).div(100)) && paymentToken.transfer(devWallet, _amount.mul(10).div(100)) , "Token transfer failed!");
        stakingData[msg.sender][_contractAddress][_tokenId].valueWithdrawn = _valueWhitdrawn + _amount;
        stakingData[msg.sender][_contractAddress][_tokenId].stakingTimestamp = block.timestamp;
        if(stakingData[msg.sender][_contractAddress][_tokenId].boosted == true){
            stakingData[msg.sender][_contractAddress][_tokenId].stakingBoostTimestamp = block.timestamp;}}
        
    //Manage Transfer

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
            return ERC721A__IERC721Receiver.onERC721Received.selector;}}
