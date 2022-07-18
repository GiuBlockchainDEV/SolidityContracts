// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ | 

import "./interface.sol";
import "./abstract.sol";
import "./library.sol";

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/


contract degenDAO is Ownable, ReentrancyGuard { 

    struct proposal {
        uint idproposal;
        string textproposal;
        uint hour;
        uint timeend;}  

    proposal[] private proposals;

    using Strings for uint256;
    using SafeMath for uint256;


    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;
    
    //NFT Settings
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public NFTminted;


    bool public paused = true;
    bool public revealed = false;
    bool public DAOproposalAbilitated = false;
    
    //DAO Settings
    uint256 public quorum;
    uint private seconds_count;
    uint private weight;
    uint public lastUpdated;
    uint public lastProposal;
    uint256 public multiplier = 20;
    uint256 private percentage = 100;

    mapping(address => uint) private quantity;
    mapping(address => bool) public moderator;

    mapping(uint => bool) public quorumReached;
    mapping(uint => bool) public proposalPassed;
    mapping(uint => bool) public proposalEnded;
    mapping(uint => bool) public proposalExecuted;
    mapping(uint => uint) public proposalVotes;
    mapping(uint => uint) public proposalYes;
    mapping(uint => uint) public proposalNo;
    
    mapping (address => mapping (uint => bool)) voted;
    event received(address, uint);

    address public degen_address = 0xc8365cEC95dC891D09be55953414cac8a25B8b13;

    //CONTRACT FUNCTIONS
    fallback() external payable {}
    receive() external payable {
        emit received(msg.sender, msg.value);}
    function deposit() external payable {
        emit received(msg.sender, msg.value);}

    modifier onlyModerator() {
        require(moderator[_msgSender()] == true || owner() == _msgSender(), "Ownable: caller is not a moderator");
        _;}
    
    function createModerator(address _moderator) public {
        moderator[_moderator] = true;}
    
    function removeModerator(address _moderator) public onlyOwner {
        moderator[_moderator] = false;}

    function getBalance() public view returns (uint256) {
        return IERC721A(degen_address).balanceOf(msg.sender);}

    function totalSupply() public view returns (uint256) {
        return IERC721A(degen_address).totalSupply();}

    function create_proposal(uint _hour, string memory _propasal) public onlyModerator {
        seconds_count = (_hour * 3600) + block.timestamp;
        proposals.push(proposal({
            idproposal: lastProposal, 
            textproposal: _propasal, 
            hour: _hour,
            timeend: seconds_count}));
        lastProposal = lastProposal + 1;}

    function read_proposal(uint _idproposal) public view returns(string memory textproposal, uint timeend) {
        uint i;
	    for(i=0;i<proposals.length;i++){
  		    proposal memory e = proposals[i];
  		    if(e.idproposal == _idproposal){
    			return(
                    e.textproposal, 
                    e.timeend);}}}

    function vote(uint _idproposal, uint _vote) public nonReentrant {
        require(IERC721A(degen_address).balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalVotes[_idproposal] < IERC721A(degen_address).totalSupply(), "Vote completed");
        require(voted[msg.sender][_idproposal] == false, "Already voted");
        require(proposalEnded[_idproposal] == false || proposals[_idproposal].timeend > block.timestamp, "Proposal ended"); 
        voted[msg.sender][_idproposal] = true;
        proposalVotes[_idproposal] += 1;
        if(_vote == 0){proposalNo[_idproposal] += 1 * IERC721A(degen_address).balanceOf(msg.sender);}
        if(_vote == 1){proposalYes[_idproposal] += 1 * IERC721A(degen_address).balanceOf(msg.sender);}
        quorum = IERC721A(degen_address).totalSupply().div(percentage.div(multiplier));
        if(proposalVotes[_idproposal] >= quorum){
            quorumReached[_idproposal] = true;
            if(proposalYes[_idproposal] > proposalNo[_idproposal]){
                proposalPassed[_idproposal] = true;
                if(proposalYes[_idproposal] == totalSupply()){
                    proposalEnded[_idproposal] = true;}}
            else{
                proposalPassed[_idproposal] = false;}}}

    function setContractAddress(address _newAddr) public onlyModerator {
        degen_address = _newAddr;}

    function setMultiplierQuorum(uint _multiplier) public onlyOwner {
        //Exemple: _multiplier of 20% = 20
        multiplier = _multiplier;}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyModerator nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}
    
    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyModerator nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}

    function transferEther(address _to, uint _amount) public onlyModerator nonReentrant {
        (bool os, ) = payable(_to).call{value: _amount}('');
        require(os);}}
