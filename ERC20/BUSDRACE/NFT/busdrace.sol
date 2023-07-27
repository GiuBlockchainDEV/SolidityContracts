// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./contract.sol";
import "./library.sol";

contract busdrace is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    struct Purchase {
    address buyer;
    uint256 amountPaid;}

    mapping(uint256 => Purchase) public tokenId;
    

    IERC20 public paymentToken;

    address public treasuryWallet;
    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public contractState = 0;
    bool public revealed = false;

    mapping (address => bool) public proofed;
    mapping (address => uint) public whitelisted;
    mapping (address => uint) public minted;

    uint256 public mintedNFT;
    uint256 public lastMintedTokenId;
    uint256 public maxSupply;
    uint256 public maxWalletAmount = 1;
    uint256 public priceNFT;
    string public hiddenMetadataUri = "ipfs://---/hidden.json";
    address public wallet_1 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address public wallet_2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public wallet_3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

    string public _tokenName = "Test1";
    string public _tokenSymbol = "FRR";
    uint256 public _maxSupply_ = 10000;
    address public _token_ = 0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d;
    uint256 public _price_ = 100;

    constructor() ERC721A(_tokenName, _tokenSymbol) {
        paymentToken = IERC20(_token_);  
        priceNFT = _price_;
        maxSupply = _maxSupply_;}
    
    /*
    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _maxSupply, address _token, uint256 _price) ERC721A(_tokenName, _tokenSymbol) {
        paymentToken = IERC20(_token);  
        priceNFT = _price;
        maxSupply = _maxSupply;}

    */


    modifier mintCompliance(uint256 _mintAmount) {
        //require(contractState > 0, "Mint Disactivated!");
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
        uint256 _mintedAmountWallet = minted[_msgSender()] + _mintAmount;
        _;}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(paymentToken.balanceOf(msg.sender) >= priceNFT.mul(_mintAmount), "Insufficient token balance");
        uint256 _amount = priceNFT.mul(_mintAmount);
        require(paymentToken.transferFrom(msg.sender, wallet_1, _amount.mul(90).div(100)), "Token transfer failed");
        require(paymentToken.transferFrom(msg.sender, wallet_2, _amount.mul(7).div(100)), "Token transfer failed");
        require(paymentToken.transferFrom(msg.sender, wallet_3, _amount.mul(3).div(100)), "Token transfer failed");
        _;}

    function setPrice(uint256 _price) public onlyOwner {
        //BUSD cost
        priceNFT = _price;}

    function mint(uint256 _mintAmount) public mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;
        mintedNFT += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
        
        // Record the purchase information
        for (uint256 i = 0; i < _mintAmount; i++) {
            lastMintedTokenId += 1;
            Purchase memory newPurchase = Purchase({
                buyer: _msgSender(),
                amountPaid: priceNFT});

            tokenId[lastMintedTokenId] = newPurchase;}}

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

    function setTreasury(address _to) public onlyOwner {
        treasuryWallet = _to;}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}
        
    function withdrawEther() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);}
    }
