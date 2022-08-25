// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./context.sol";

abstract contract Ownable is Context {

    address private _owner;
    address private _intermediary;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());}
        
    function owner() public view virtual returns (address) {
        return _owner;}
    
    function intermediary() public view virtual returns (address) {
        return _intermediary;}
        
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;}

    modifier onlyIntermediary() {
        require(intermediary() == _msgSender(), "Ownable: caller is not the intermediary");
        _;}

    function setIntermediary(address newIntermediary) public virtual onlyOwner {
        require(newIntermediary != address(0), "Ownable: new intermediary is the zero address");
        _intermediary = newIntermediary;}
        
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));}
        
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);}
        
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);}}
