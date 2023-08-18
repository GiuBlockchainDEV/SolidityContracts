// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;}

    //Prevents a contract from calling itself, directly or indirectly.
    //Calling a `nonReentrant` function from another `nonReentrant`function is not supported. 
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;}}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}}

abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        //dev Initializes the contract setting the deployer as the initial owner
        _transferOwnership(_msgSender());}

    function owner() public view virtual returns (address) {
        //Returns the address of the current owner
        return _owner;}

    modifier onlyOwner() {
        //Throws if called by any account other than the owner
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;}

    function renounceOwnership() public virtual onlyOwner {
        //Leaves the contract without owner
        _transferOwnership(address(0));}

    function transferOwnership(address newOwner) public virtual onlyOwner {
        //Transfers ownership of the contract to a new account (`newOwner`)
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);}

    function _transferOwnership(address newOwner) internal virtual {
        //Transfers ownership of the contract to a new account (`newOwner`)
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);}}

contract Allowance is Ownable {

    event AllowanceChanged(address indexed _from, address indexed _toWhom, uint256 _oldAmount, uint256 _newAmount);

    mapping(address => uint256) public allowance;

    bool isAllowanceSet;

    function isOwner() internal view returns (bool) {
        return owner() == msg.sender;
    }

    function setAllowance(address _who, uint256 _amount) public onlyOwner {
        require(
            isAllowanceSet ==  false,
            "Allowance Already Set"
        );
        emit AllowanceChanged(msg.sender, _who, allowance[_who], _amount);
        allowance[_who] = _amount;
        isAllowanceSet = true;
    }

    modifier ownerOrAllowed(uint256 _amount) {
        require(
            isOwner() || allowance[msg.sender] >= _amount,
            "You're not allwoed"
        );
        _;
    }

    function _reduceAllowance(address _who, uint256 _amount) internal ownerOrAllowed(_amount) {
        emit AllowanceChanged(msg.sender, _who, allowance[_who], allowance[_who] - _amount);
        if (isAllowanceSet) {
        allowance[_who] -= _amount;
        } else {
            revert ("Allowance not set");
        }
    }

    function increaseAllowance(address _who, uint256 _amount) public onlyOwner {
        emit AllowanceChanged(msg.sender, _who, allowance[_who], allowance[_who] + _amount);
        if (isAllowanceSet) {
        allowance[_who] += _amount;
         } else {
            revert ("Allowance not set");
        }
    }
}

contract Shared_Wallet is Allowance {

    event MoneySent(address indexed _beneficiary, uint256 _amount);
    event MoneyReceived(address indexed _from, uint256 _amount);


// @dev  owner and allowed users can withdraw money. owner has access to withdraw unlimited amount but allowed users allowance will be reduced. 
// @param  adress to whom user want to send money (user's own account or other account)
// @param  amount to be withdrawn
// emits MoneySent event.

  function withdrawMoney(
      address payable _to, 
      uint256 _amount
      ) public payable ownerOrAllowed(_amount) {
        require(
            _amount <= address(this).balance,
            "Contract out of money"
        );
        if(!isOwner()) {
            _reduceAllowance(msg.sender, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
       
    }

// @dev  this can only be called by the owner if he wants to reduce the allowance of a user.
// **  called the internal function from 'Allowance.sol' to make it callable by the owner externally.

    function reduceAllowance(
        address _who, 
        uint256 _amount
        ) public onlyOwner {
        super._reduceAllowance(_who, _amount);
    }

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

     function renounceOwnership() public override virtual onlyOwner {
        revert("can't renounce ownership"); // overrided the renounceOwnership in Ownable.sol
    }
}    
