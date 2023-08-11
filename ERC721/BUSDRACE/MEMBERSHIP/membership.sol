// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./contract.sol";
import "./library.sol";

contract membership is ERC721A, Ownable, ReentrancyGuard {
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

    uint256 public nominalPriceNFT = 99*(10**18);
    uint256 public priceNFT = 98*(10**18);
    string public hiddenMetadataUri = "ipfs://---/hidden.json";

    string public _tokenName = "Membership NFT";
    string public _tokenSymbol = "MNFT";
    uint256 public _maxSupply_ = 10000;
    address private token_ = 0xaff046a6AaE052FcB35e5D7fD3Acf18FC68D8036;

    constructor() ERC721A(_tokenName, _tokenSymbol) {
        paymentToken = IERC20(token_);  
        maxSupply = _maxSupply_;}

    //Moderator

    address public moderator;

    modifier onlyModerator() {
        require(msg.sender == owner() || msg.sender == moderator, "Not owner or moderator!");
        _;}

    function setModerator(address _moderator) external onlyOwner {
        moderator = _moderator;}

    function setPrice(uint256 _price) external onlyModerator {
        priceNFT = _price;}

    function getPrice() external view returns(uint256, uint256) {
        return (nominalPriceNFT, priceNFT);
    }
    
    function setPaymentToken(address _token) external onlyModerator {
        paymentToken = IERC20(_token);}

    function setTreasury(address _to) external onlyModerator {
        treasuryWallet = _to;}

    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "Contract is paused!");
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
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

    function burn(uint256 _tokenId) external {
        _burn(_tokenId, true); }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function setRevealed(bool _state) external onlyOwner {
        //Reveal the token URI of the NFTs
        revealed = _state;}

    function setPaused(bool _state) external onlyOwner {
        //Unlock the contract
        paused = _state;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyModerator {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
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
