// SPDX-License-Identifier: MIT

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ | 

pragma solidity ^0.8.14;

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}}

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

interface new_type_IERC20 {
    function transfer(address, uint) external returns (bool);}

interface old_type_IERC20 {
    function transfer(address, uint) external;}

contract MultisigDH is Ownable, ReentrancyGuard { 

    struct proposal {
        uint idproposal;
        string textproposal;
        uint hour;
        uint timeend;
        uint qty_vote;
        uint yes;
        uint no;
        bool quorumreached;
        bool passed;
        bool ended;
        //0 -> decision proposal, 1 -> ether transfer, 2 -> anyERC20 transfer, 3 -> oldERC20 transfer
        uint typeproposal;
        //wei amount -> import * 10^decimals
        uint amount;
        address tokenAddr;
        address to;
        bool payed;}
    
    struct vote_weight {
        uint weight;
        string role;
        bool DAOmember;}

    uint public multisig = 8;
    uint public quorum = 4;
    uint private seconds_count;
    uint private weight;
    uint public lastUpdated;
    uint public lastProposal;
    mapping(address => uint) private quantity;
    mapping(address => vote_weight) public DAOweight;
    mapping (address => mapping (uint => bool)) voted;
    proposal[] private proposals;

    event received(address, uint);

    function setMember(address _addr, uint _weight, string memory _role, bool _member) public onlyOwner {
        DAOweight[_addr].weight = _weight;
        DAOweight[_addr].role = _role;
        DAOweight[_addr].DAOmember = _member;}

    function DAOsetMember(uint _idproposal, string memory _role) public {
        require(DAOweight[msg.sender].DAOmember == true, "Not a member of the DAO");
        require(proposals[_idproposal].ended == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposals[_idproposal].passed == true, "Proposal not passed");  
        require(proposals[_idproposal].typeproposal == 4, "Wrong function");
        DAOweight[proposals[_idproposal].to].role = _role;
        if(proposals[_idproposal].amount > 0){
            DAOweight[proposals[_idproposal].to].weight = proposals[_idproposal].amount;
            DAOweight[proposals[_idproposal].to].DAOmember = true;}
        if(proposals[_idproposal].amount == 0){
            DAOweight[proposals[_idproposal].to].weight = 0;
            DAOweight[proposals[_idproposal].to].DAOmember = false;}}

    function getweight(address _addr) public view returns(uint, string memory, bool) {
        return(DAOweight[_addr].weight, DAOweight[_addr].role, DAOweight[_addr].DAOmember);}

    function create_proposal(uint _hour, string memory _propasal, uint _typeproposal, uint _amount, address _tokenAddr, address _to) public {
        require(DAOweight[msg.sender].DAOmember == true, "Not a member of the DAO");
        seconds_count = (_hour * 3600) + block.timestamp;
        proposals.push(proposal({
            idproposal: lastProposal, 
            textproposal: _propasal, 
            hour: _hour,
            timeend: seconds_count, 
            qty_vote: 0, 
            yes: 0, 
            no: 0, 
            quorumreached: false, 
            passed: false, 
            ended: false,
            typeproposal: _typeproposal, 
            amount: _amount,
            tokenAddr: _tokenAddr,
            to: _to,
            payed: false}));
        lastProposal = lastProposal + 1;}

    function read_proposal(uint _idproposal) public view returns(string memory, uint, uint, uint, uint, bool, bool, uint, uint, address, address, bool) {
        uint i;
	    for(i=0;i<proposals.length;i++){
  		    proposal memory e = proposals[i];
  		    if(e.idproposal == _idproposal){
    			return(
                    e.textproposal, 
                    e.timeend, 
                    e.qty_vote, 
                    e.yes, 
                    e.no, 
                    e.quorumreached, 
                    e.passed, 
                    e.typeproposal, 
                    e.amount,
                    e.tokenAddr,
                    e.to,
                    e.payed);}}}

    function vote(uint _idproposal, uint _vote) public {
        require(DAOweight[msg.sender].DAOmember == true, "Not a member of the DAO");
        require(proposals[_idproposal].qty_vote < multisig, "Vote completed");
        require(voted[msg.sender][_idproposal] == false, "Already voted");
        voted[msg.sender][_idproposal] = true;
        proposals[_idproposal].qty_vote += 1;
        weight = DAOweight[msg.sender].weight;
        if(_vote == 0){proposals[_idproposal].no += 1 * weight;}
        if(_vote == 1){proposals[_idproposal].yes += 1 * weight;}
        if(proposals[_idproposal].qty_vote >= quorum){
            proposals[_idproposal].quorumreached = true;
            if(proposals[_idproposal].yes > proposals[_idproposal].no){
                proposals[_idproposal].passed = true;}
            else{
                proposals[_idproposal].passed = false;}
            if(proposals[_idproposal].qty_vote == multisig - 1){
                proposals[_idproposal].ended = true;}}}

    //1 day -> 86400 seconds
    function updateTimestamp() public {
        lastUpdated = block.timestamp;}

    function deposit() external payable {
        emit received(msg.sender, msg.value);}

    fallback() external payable {}

    receive() external payable {
        emit received(msg.sender, msg.value);}

    function DAOtransferERC20(uint _idproposal) public nonReentrant {
        require(DAOweight[msg.sender].DAOmember == true, "Not a member of the DAO");
        require(proposals[_idproposal].ended == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposals[_idproposal].passed == true, "Proposal not passed");  
        require(proposals[_idproposal].typeproposal == 2, "Wrong Transfer function");
        require(proposals[_idproposal].payed == false, "Already paid");  
        require(new_type_IERC20(proposals[_idproposal].tokenAddr).transfer(proposals[_idproposal].to, proposals[_idproposal].amount), "Could not transfer out tokens!");
        proposals[_idproposal].payed = true;}

    function DAOtransferERC20O(uint _idproposal) public nonReentrant {  
        require(DAOweight[msg.sender].DAOmember == true, "Not a member of the DAO");
        require(proposals[_idproposal].ended == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");
        require(proposals[_idproposal].passed == true, "Proposal not passed"); 
        require(proposals[_idproposal].typeproposal == 3, "Wrong Transfer function");   
        require(proposals[_idproposal].payed == false, "Already paid"); 
        old_type_IERC20(proposals[_idproposal].tokenAddr).transfer(proposals[_idproposal].to, proposals[_idproposal].amount);
        proposals[_idproposal].payed = true;}

    function DAOtransferEther(uint _idproposal) public nonReentrant {
        require(DAOweight[msg.sender].DAOmember == true, "Not a member of the DAO");
        require(proposals[_idproposal].ended == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposals[_idproposal].passed == true, "Proposal not passed");   
        require(proposals[_idproposal].typeproposal == 1, "Wrong Transfer function"); 
        require(proposals[_idproposal].payed == false, "Already paid"); 
        (bool os, ) = payable(proposals[_idproposal].to).call{value: proposals[_idproposal].amount}('');
        require(os);
        proposals[_idproposal].payed = true;}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}

    function transferEther(address _to, uint _amount) public onlyOwner nonReentrant {
        (bool os, ) = payable(_to).call{value: _amount}('');
        require(os);}}
