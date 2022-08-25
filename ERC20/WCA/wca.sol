// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./address.sol";
import "./safemath.sol";
import "./ierc20.sol";
import "./context.sol";
import "./ownable.sol";

contract WorldCupApesWhitelist is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public wallet;
    uint256 public startUnstakeTimestamp = 1669849200;
    uint256 public price = 28;
    uint256 public priceDivider = 100;
    uint256 public emissionRate = 66;
    uint256 public emissionDivider = 10000;
    uint256 public usdtPow = 12;
    bool public purchaseLive = false;
    mapping(address => uint256) internal stakerToUSDT;
    mapping(address => uint256) internal stakerToTokens;
    mapping(address => uint256) internal stakerToInitialTokens;
    mapping(address => uint256) internal stakerToLastClaim;

    IERC20 private USDT;
    IERC20 private WCAToken;

    modifier canUnstake {
        require(block.timestamp >= startUnstakeTimestamp, "You can't already unstake tokens");
        _;}

    modifier purchaseEnabled {
        require(purchaseLive, "Purchase not live");
        _;}

    constructor(address _WCAToken, address _USDT, address _wallet) {
        WCAToken = IERC20(_WCAToken);
        USDT = IERC20(_USDT);
        wallet = _wallet;}

    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;}

    function setStartUnstakeTimestamp(uint256 timestamp) external onlyOwner {
        startUnstakeTimestamp = timestamp;}

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;}

    function setPriceDivider(uint256 _priceDivider) external onlyOwner {
        priceDivider = _priceDivider;}

    function setEmissionRate(uint256 _emissionRate) external onlyOwner {
        emissionRate = _emissionRate;}

    function setEmissionDivider(uint256 _emissionDivider) external onlyOwner {
        emissionDivider = _emissionDivider;}

    function setUsdtPow(uint256 _usdtPow) external onlyOwner {
        usdtPow = _usdtPow;}

    function togglePurchaseLive() external onlyOwner {
        purchaseLive = !purchaseLive;}

    function bonus(address _address, uint256 value) external onlyOwner {
        stakerToTokens[_address] = stakerToTokens[_address].add(value);
        stakerToInitialTokens[_address] = stakerToInitialTokens[_address].add(value);}

    function reduce(address _address, uint256 value) external onlyOwner {
        stakerToTokens[_address] = stakerToTokens[_address].sub(value);
        stakerToInitialTokens[_address] = stakerToInitialTokens[_address].sub(value);}

    function buyIntermediary(address _address, uint256 _value, uint _level) external purchaseEnabled onlyIntermediary {
        uint256 balance = USDT.balanceOf(msg.sender);
        require(balance > 0, "You have no USDT");
        require(USDT.allowance(msg.sender, address(this)) >= _value, "First approve to buy");
        USDT.safeTransferFrom(msg.sender, wallet, _value);

        uint256 _price;

        if(_level == 1){
            _price = 10;}
        else if(_level == 2){
            _price = 20;}
        else if(_level == 3){
            _price = 30;}
        else if(_level == 4){
            _price = 40;}

        uint256 valueInWCA = _value.mul(10 ** usdtPow).mul(priceDivider).div(_price);
        stakerToUSDT[_address] = stakerToUSDT[_address].add(_value);
        stakerToTokens[_address] = stakerToTokens[_address].add(valueInWCA);
        stakerToInitialTokens[_address] = stakerToInitialTokens[_address].add(valueInWCA);}

    function buy(address _address, uint256 _value) external purchaseEnabled {
        uint256 balance = USDT.balanceOf(msg.sender);
        require(balance > 0, "You have no USDT");
        require(USDT.allowance(msg.sender, address(this)) >= _value, "First approve to buy");

        USDT.safeTransferFrom(msg.sender, wallet, _value);

        uint256 valueInWCA = _value.mul(10 ** usdtPow).mul(priceDivider).div(price);
        stakerToUSDT[_address] = stakerToUSDT[_address].add(_value);
        stakerToTokens[_address] = stakerToTokens[_address].add(valueInWCA);
        stakerToInitialTokens[_address] = stakerToInitialTokens[_address].add(valueInWCA);}

    function claim(address _address) external canUnstake {
        require(stakerToTokens[_address] > 0 && stakerToInitialTokens[_address] > 0, "You have no tokens staked");
        uint256 fromTimestamp = startUnstakeTimestamp;
        if(stakerToLastClaim[_address] > startUnstakeTimestamp){
        fromTimestamp = stakerToLastClaim[_address];}
        uint256 rewards = block.timestamp.sub(fromTimestamp).mul(stakerToInitialTokens[_address]).mul(emissionRate).div(emissionDivider).div(86400);
        if(rewards > stakerToTokens[_address]){
        rewards = stakerToTokens[_address];
        stakerToTokens[_address] = 0;} 
        else {
        stakerToTokens[_address] = stakerToTokens[_address].sub(rewards);}
        stakerToLastClaim[_address] = block.timestamp;
        WCAToken.transferFrom(owner(), _address, rewards);}

    function getTotalClaimable(address _address) external view returns (uint256) {
        return stakerToInitialTokens[_address];}

    function getRemainingClaimable(address _address) external view returns (uint256) {
        return stakerToTokens[_address];}

    function getClaimable(address _address) external view returns (uint256) {
        if(stakerToTokens[_address] <= 0 || stakerToInitialTokens[_address] <= 0 || block.timestamp < startUnstakeTimestamp) {
        return 0;}
        uint256 fromTimestamp = startUnstakeTimestamp;
        if(stakerToLastClaim[_address] > startUnstakeTimestamp){
        fromTimestamp = stakerToLastClaim[_address];}
        uint256 rewards = block.timestamp.sub(fromTimestamp).mul(stakerToInitialTokens[_address]).mul(emissionRate).div(emissionDivider).div(86400);
        if(rewards > stakerToTokens[_address]){
        rewards = stakerToTokens[_address];}
        return rewards;}

    //Mostra quanti USDT ha speso un indirizzo
    function getSpentUSDT(address _address) external view returns (uint256) {
        return stakerToUSDT[_address];}}
