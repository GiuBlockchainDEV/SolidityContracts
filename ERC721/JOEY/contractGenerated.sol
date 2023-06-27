// SPDX-License-Identifier: MIT

import "./contract.sol";
import "./library.sol";

pragma solidity ^0.8.14;

// Definisci il contratto ERC721 che vuoi creare
contract remosworldsubcontract is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    IERC721A public remosAddress;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public list_one;

    uint256 public contractState = 0;
    bool public revealed = false;
    bool public paused = true;
    
    mapping(address => uint) public minted;
    mapping(uint => bool) public idMinted;

    uint256 public maxSupply;
    uint256 public maxWalletAmount;
    

    uint256 public mintedNFT;
    
    uint256 public priceNFT = 0 ether;
    string public hiddenMetadataUri = "ipfs://QmSmo5bYtZDKrQQdXwobAXwbBUVFUU9DE7AgxCuSUHiCLe";

    string public _name = "Test";
    string public _symbol = "TST";
    uint256 public _maxSupply = 500;
    address public _erc721Address = 0xf8D81A1805FA4d973b455746e60b62494bB5DAA7;

    
    constructor() ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        remosAddress = IERC721A(_erc721Address);}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= priceNFT * _mintAmount, "Insufficient Funds");
        _;}

    function checkBalance(address _addr) public view returns (uint256) {
        uint256 balance = remosAddress.balanceOf(_addr);
        return balance;}

    /*MUST DO OUT OF THE CONTRACT
    function checkMintAvailable(address _addr) public view returns (uint256[] memory) {
        uint256 totalSupply = remosAddress.totalSupply();
        uint256 ownershipCount = checkBalance(_addr);
        uint256[] memory ownedTokens = new uint256[](ownershipCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (remosAddress.ownerOf(i) == _addr) {
                ownedTokens[counter] = i;
                counter++;}}
        return ownedTokens;}
    

    function checkMintAvailable(address _addr, uint256 _start, uint256 _end) public view returns (uint256[] memory) {
        uint256 _ownershipCount;

        for (uint256 i = _start; i <= _end; i++) {
            if (remosAddress.ownerOf(i) == _addr) {
                _ownershipCount ++;}}

        uint256[] memory ownedTokens = new uint256[](_ownershipCount);
        uint256 counter = 0;
        
        for (uint256 i = _start; i <= _end; i++) {
            if (remosAddress.ownerOf(i) == _addr) {
                ownedTokens[counter] = i;
                counter++;}}
        return ownedTokens;}
    */

    function checkNFT(uint256[]memory _tokenId) public view returns (uint256[] memory, uint256[] memory) {
        
        uint256 _mintedAmount;
        uint256 _notMintedAmount;

        for (uint256 i = 0; i < _tokenId.length; i++) {
            if (idMinted[_tokenId[i]] == false) {
                _notMintedAmount ++;}
            else {
                _mintedAmount ++;}}

        uint256[] memory _notMintedNFT = new uint256[](_notMintedAmount);
        uint256[] memory _mintedNFT = new uint256[](_mintedAmount);
        uint256 _counterNotMinted;
        uint256 _counterMinted;

        for (uint256 i = 0; i < _tokenId.length; i++) {
            if (idMinted[_tokenId[i]] == false) {
                _notMintedNFT[_counterNotMinted] = _tokenId[i];
                _counterNotMinted ++;}
            else {
                _mintedNFT[_counterMinted] = _tokenId[i];
                _counterMinted ++;}}

        return (_notMintedNFT, _mintedNFT);}

    function setPrice(uint256 _price) public onlyOwner {
        //Ether cost
        priceNFT = _price;}

    function ownerBlacklistBatchNFT(uint256[]memory _nftId) public onlyOwner {
        for (uint256 i = 0; i < _nftId.length; i++) {
            idMinted[_nftId[i]] = true;}}

    function blacklistBatchNFT(uint256[]memory _nftId) private {
        for (uint256 i = 0; i < _nftId.length; i++) {
            idMinted[_nftId[i]] = true;}}

    function mint(uint256[] memory _tokenId) public payable mintPriceCompliance(_tokenId.length) nonReentrant {
        require(paused == false, "Contract paused");
        for (uint256 i = 0; i < _tokenId.length; i++) {
            require(remosAddress.ownerOf(_tokenId[i]) == _msgSender() && idMinted[_tokenId[i]] == false, "Not NFT owner or NFT not valid");}
        _safeMint(_msgSender(), _tokenId.length);
        blacklistBatchNFT(_tokenId);}

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

    function setPause(bool _state) public onlyOwner {
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
        uint256 _mintedNFT = totalSupply();
        uint256 _totalSupply = maxSupply;
        return (_mintedNFT, _totalSupply);}

    receive() external payable {}

    fallback() external payable {}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}
        
    function withdrawEther(address _to) public onlyOwner nonReentrant {
        (bool os, ) = payable(_to).call{value: address(this).balance}('');
        require(os);}}
