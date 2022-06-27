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
import "./contract.sol";
import "./abstract.sol";
import "./library.sol";

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

contract MultisigDH is ERC721A, Ownable, ReentrancyGuard { 

    struct proposal {
        uint idproposal;
        string textproposal;
        uint hour;
        uint timeend;
        uint typeproposal;
        //wei amount -> import * 10^decimals
        uint value;
        string extraData;
        address tokenAddr;
        address to;}   

    using Strings for uint256;
    using SafeMath for uint256;


    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;
    
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public NFTminted;


    bool public paused = true;
    bool public revealed = false;
    
    uint256 public quorum;
    uint private seconds_count;
    uint private weight;
    uint public lastUpdated;
    uint public lastProposal;
    uint256 public multiplier = 20;
    uint256 private percentage = 100;

    mapping(address => uint) private quantity;

    mapping(uint => bool) public quorumReached;
    mapping(uint => bool) public proposalPassed;
    mapping(uint => bool) public proposalEnded;
    mapping(uint => bool) public proposalExecuted;
    mapping(uint => uint) public proposalVotes;
    mapping(uint => uint) public proposalYes;
    mapping(uint => uint) public proposalNo;
    
    mapping (address => mapping (uint => bool)) voted;
    proposal[] private proposals;
    event received(address, uint);

    constructor(string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri) 
        ERC721A(_tokenName, _tokenSymbol, _msgSender()) {
            maxSupply = _maxSupply;
            setMaxMintAmountPerTx(_maxMintAmountPerTx);
            setHiddenMetadataUri(_hiddenMetadataUri);}

    //CONTRACT FUNCTIONS
    fallback() external payable {}
    receive() external payable {
        emit received(msg.sender, msg.value);}
    function deposit() external payable {
        emit received(msg.sender, msg.value);}
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}  

    function create_proposal(uint _hour, string memory _propasal, uint _typeproposal, uint _amount, address _tokenAddr, address _to, string memory _extraData) public {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        seconds_count = (_hour * 3600) + block.timestamp;
        proposals.push(proposal({
            idproposal: lastProposal, 
            textproposal: _propasal, 
            hour: _hour,
            timeend: seconds_count, 
            typeproposal: _typeproposal, 
            value: _amount,
            extraData: _extraData,
            tokenAddr: _tokenAddr,
            to: _to}));
        lastProposal = lastProposal + 1;}

    function read_proposal(uint _idproposal) public view returns(string memory textproposal, uint timeend, uint typeproposal, uint value, string memory extraData, address tokenAddr, address to) {
        require(proposals[_idproposal].typeproposal > 0, "Wrong function");
        uint i;
	    for(i=0;i<proposals.length;i++){
  		    proposal memory e = proposals[i];
  		    if(e.idproposal == _idproposal){
    			return(
                    e.textproposal, 
                    e.timeend, 
                    e.typeproposal, 
                    e.value,
                    e.extraData,
                    e.tokenAddr,
                    e.to);}}}

    function vote(uint _idproposal, uint _vote) public {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalVotes[_idproposal] < totalSupply(), "Vote completed");
        require(voted[msg.sender][_idproposal] == false, "Already voted");
        require(proposals[_idproposal].typeproposal > 0, "Wrong function");
        voted[msg.sender][_idproposal] = true;
        proposalVotes[_idproposal] += 1;
        if(_vote == 0){proposalNo[_idproposal] += 1 * balanceOf(msg.sender);}
        if(_vote == 1){proposalYes[_idproposal] += 1 * balanceOf(msg.sender);}
        quorum = totalSupply().div(percentage.div(multiplier));
        if(proposalVotes[_idproposal] >= quorum){
            quorumReached[_idproposal] = true;
            if(proposalYes[_idproposal] > proposalNo[_idproposal]){
                proposalPassed[_idproposal] = true;
                if(proposalYes[_idproposal] == totalSupply()){
                    proposalEnded[_idproposal] = true;}}
            else{
                proposalPassed[_idproposal] = false;}}}

//DAO FUNCTIONS
    //SET URI PREFIX
    //PROPOSAL -> 1
    function DAOsetUriPrefix(uint _idproposal) public onlyOwner {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposalPassed[_idproposal] == true, "Proposal not passed");  
        require(proposals[_idproposal].typeproposal == 1, "Wrong function");
        require(proposalExecuted[_idproposal] == false, "Already done");  

        uriPrefix = proposals[_idproposal].extraData;
        
        proposalExecuted[_idproposal] = true;}

    //SET MULTIPLIER QUORUM
    //PROPOSAL -> 2
    function DAOsetMultiplierQuorum(uint _idproposal) public {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already done"); 
        require(proposals[_idproposal].typeproposal == 2, "Wrong function");

        multiplier = proposals[_idproposal].value;
        
        proposalExecuted[_idproposal] = true;}

    //MINT FOR AN ADDRESS
    //PROPOSAL -> 3
    function DAOmintForAddress(uint _idproposal) public nonReentrant {
        //Mint new governance NFTs
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(totalSupply() + proposals[_idproposal].value <= maxSupply, "Max supply exceeded!");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already done"); 
        require(proposals[_idproposal].typeproposal == 3, "Wrong function");

        NFTminted += proposals[_idproposal].value;
        _safeMint(proposals[_idproposal].to, proposals[_idproposal].value);
        
        proposalExecuted[_idproposal] = true;}

    //TRANSFER ERC20
    //PROPOSAL -> 4
    function DAOtransferERC20(uint _idproposal) public nonReentrant {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already paid"); 
        require(proposals[_idproposal].typeproposal == 4, "Wrong function");

        new_type_IERC20(proposals[_idproposal].tokenAddr).transfer(proposals[_idproposal].to, proposals[_idproposal].value);
        
        proposalExecuted[_idproposal] = true;}

    //TRANSFER ERC20 OLD
    //PROPOSAL -> 5
    function DAOtransferERC20O(uint _idproposal) public nonReentrant {  
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already paid"); 
        require(proposals[_idproposal].typeproposal == 5, "Wrong function");

        old_type_IERC20(proposals[_idproposal].tokenAddr).transfer(proposals[_idproposal].to, proposals[_idproposal].value);
        
        proposalExecuted[_idproposal] = true;}

    //TRANSFER ETHER
    //PROPOSAL -> 6
    function DAOtransferEther(uint _idproposal) public nonReentrant {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already paid"); 
        require(proposals[_idproposal].typeproposal == 6, "Wrong function");

        (bool os, ) = payable(proposals[_idproposal].to).call{value: proposals[_idproposal].value}('');
        require(os);

        proposalExecuted[_idproposal] = true;}

//OWNER FUNCTIONS
    function setMultiplierQuorum(uint _multiplier) public onlyOwner {
        //Exemple: _multiplier of 20% = 20
        multiplier = _multiplier;}

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function setPaused(bool _state) public onlyOwner {
        paused = _state;}

    function setRevealed(bool _state) public onlyOwner {
        //Reveal the token URI of the NFTs
        revealed = _state;}

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        //Minted by Owner without any cost, doesn't count on minted quantity
        NFTminted += _mintAmount;
        _safeMint(_receiver, _mintAmount);}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}
    
    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}

    function transferEther(address _to, uint _amount) public onlyOwner nonReentrant {
        (bool os, ) = payable(_to).call{value: _amount}('');
        require(os);}}
