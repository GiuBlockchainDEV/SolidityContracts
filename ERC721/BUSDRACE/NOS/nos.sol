// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./contract.sol";
import "./library.sol";

contract nos is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    IERC20 public paymentToken;

    address public treasuryWallet;
    string public uriPrefix = "";
    string public uriSuffix = ".json";

    bool public revealed = false;
    bool public paused = true;
    
    mapping (address => uint) public minted;

    uint256 public mintedNFT;
    uint256 public lastMintedTokenId;
    uint256 public maxSupply = 10000;
    bool internal lockPause;

    uint256 public decimals = 18;
    uint256 public nominalPriceNFT = 199*(10**decimals);
    uint256 public priceNFT = nominalPriceNFT;
    string public hiddenMetadataUri = "ipfs://---/hidden.json";

    string public _tokenName = "NOS BUSDRACE";
    string public _tokenSymbol = "NOS";
    uint256 public _maxSupply_ = 10000;
    address private token_ = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;


    constructor() ERC721A(_tokenName, _tokenSymbol) {
        paymentToken = IERC20(token_);}

    //Moderator

    address public moderator;

    modifier onlyModerator() {
        require(msg.sender == owner() || msg.sender == moderator, "Not owner or moderator!");
        _;}

    function setModerator(address _moderator) public onlyOwner {
        moderator = _moderator;}

    function setPrice(uint256 _price, uint256 _decimals) public onlyModerator {
        decimals = _decimals;
        priceNFT = _price*(10**decimals);}

    function getPrice() external view returns(uint256, uint256) {
        return (nominalPriceNFT, priceNFT);}
    
    function setPaymentToken(address _token) public onlyOwner {
        paymentToken = IERC20(_token);}

    function setTreasury(address _to) public onlyOwner {
        treasuryWallet = _to;}

    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "Contract is paused!");
        require(_mintAmount == 1 , "Invalid mint amount!");
        require(minted[msg.sender] == 0 , "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
        require(balanceOf(msg.sender) == 0, "Max 1 mint for wallet");
        _;}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(paymentToken.balanceOf(msg.sender) >= priceNFT.mul(_mintAmount), "Insufficient token balance");
        uint256 _amount = priceNFT.mul(_mintAmount);
        require(paymentToken.transferFrom(msg.sender, treasuryWallet, _amount), "Token transfer failed");
        _;}

    function mint(uint256 _mintAmount) public mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;
        mintedNFT += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);}

    function burn(uint256 _tokenId) public {
        _burn(_tokenId, true); }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function setRevealed(bool _state) public onlyModerator {
        //Reveal the token URI of the NFTs
        revealed = _state;}

    function setPaused(bool _state) public onlyModerator {
        //Unlock the contract
        require(!lockPause, "This parameter can not modified any more");
        lockPause = true;
        paused = _state;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyModerator {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyModerator {
        uriPrefix = _uriPrefix;}

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyModerator {
        uriSuffix = _uriSuffix;}

    function getMinted() public view returns (uint256, uint256) {
        uint256 _mintedNFT = mintedNFT;
        uint256 _totalSupply = maxSupply;
        return (_mintedNFT, _totalSupply);}

    receive() external payable {}

    fallback() external payable {}}
