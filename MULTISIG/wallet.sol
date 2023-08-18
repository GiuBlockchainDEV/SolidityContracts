// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./library.sol";
import "./contract.sol";

contract Shared_Wallet is Allowance {
    event EtherSent(address indexed _beneficiary, uint256 _amount);
    event EtherReceived(address indexed _from, uint256 _amount);
    event TokenSent(address indexed _beneficiary, uint256 _amount, address _token);
    event TokenReceived(address indexed _from, uint256 _amount, address _token);
    using SafeERC20 for IERC20;

    function withdrawMoney(address payable _to,  uint256 _amount) public payable ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Contract out of money");
        if(!isOwner()) {
            _reduceAllowance(msg.sender, _amount);}
        emit EtherSent(_to, _amount);
        _to.transfer(_amount);}

    function payUserETHER(address payable _to,  uint256 _amount) public payable ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Contract out of money");
        if(!isOwner()) {
            _reduceAllowance(msg.sender, _amount);}
        emit EtherSent(_to, _amount);
        _to.transfer(_amount);}

    function reduceAllowance(address _who, uint256 _amount) public onlyOwner {
        super._reduceAllowance(_who, _amount);}

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);}

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;}

    function depositTokens(address tokenAddress, uint256 amount) public {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit TokenReceived(msg.sender, amount, tokenAddress);}

    // Function to withdraw ERC-20 tokens from the contract
    function withdrawTokens(address tokenAddress, uint256 amount) public ownerOrAllowedERC20(amount, tokenAddress) {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, amount);
        emit TokenSent(msg.sender, amount, tokenAddress);}

    function payUserERC20(address tokenAddress, address receiver, uint256 amount) public ownerOrAllowedERC20(amount, tokenAddress) {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(receiver, amount);
        emit TokenSent(receiver, amount, tokenAddress);}    

     function renounceOwnership() public override virtual onlyOwner {
        revert("can't renounce ownership");}} 
