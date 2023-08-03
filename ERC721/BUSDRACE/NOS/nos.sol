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
    uint256 public maxSupply;

    uint256 public priceNFT;
    string public hiddenMetadataUri = "ipfs://---/hidden.json";

    string public _tokenName = "NOS BUSDRACE";
    string public _tokenSymbol = "NOS";
    uint256 public _maxSupply_ = 10000;
    address private token_ = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    uint256 public _price_ = 100;

    constructor() ERC721A(_tokenName, _tokenSymbol) {
        paymentToken = IERC20(token_);  
        priceNFT = _price_;
        maxSupply = _maxSupply_;}

    function setPrice(uint256 _price) public onlyOwner {
        priceNFT = _price;}
    
    function setPaymentToken(address _token) public onlyOwner {
        paymentToken = IERC20(_token);}

    function setTreasury(address _to) public onlyOwner {
        treasuryWallet = _to;}

    modifier mintCompliance(uint256 _mintAmount) {
        require(paused == false, "Mint Disactivated!");
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
        uint256 _mintedAmountWallet = minted[_msgSender()] + _mintAmount;
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
    
    function setRevealed(bool _state) public onlyOwner {
        //Reveal the token URI of the NFTs
        revealed = _state;}

    function setPaused(bool _state) public onlyOwner {
        //Unlock the contract
        paused = _state;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;}

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function getMinted() public view returns (uint256, uint256) {
        uint256 _mintedNFT = mintedNFT;
        uint256 _totalSupply = maxSupply;
        return (_mintedNFT, _totalSupply);}

    receive() external payable {}

    fallback() external payable {}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}
        
    function withdrawEther() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);}}
