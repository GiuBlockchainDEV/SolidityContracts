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

contract degenNFT is ERC721A, Ownable, ReentrancyGuard, IERC4907 {

    struct UserInfo{
        // address of user role
        address user;   
        // unix timestamp, user expires
        uint64 expires;}

    mapping (uint256  => UserInfo) private _users;

    using Strings for uint256;

    string public mUriPrefix = "";
    string public fUriPrefix = "";
    string public xUriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public costWhitelist = 0.01 ether;
    uint256 public costPublicSale = 0.02 ether;
    uint256 public costGenderChange = 0.02 ether;
    uint256 public NFTminted;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    mapping(address => bool) public whitelisted;
    mapping(address => uint) public minted;
    mapping(uint => uint) public edited;

    mapping(uint => uint) public sex;
    mapping(uint => mapping (uint => string)) public uri;


    string public tokenName = "DEGEN NFT COLLECTION";
    string public tokenSymbol = "DNC";
    uint256 public maxSupply = 10420;
    uint256 public mintableSupply = 10000;
    uint256 public maxMintAmountPerTx = 200;
    string public hiddenMetadataUri = "ipfs://QmRp5WBQuC56cVJJ5qnXkprtNT64ofdfa8nADfhVEWPhe9";
    
    constructor() ERC721A(tokenName, tokenSymbol) {
            maxSupply = maxSupply;
            setMaxMintAmountPerTx(maxMintAmountPerTx);
            setHiddenMetadataUri(hiddenMetadataUri);}

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= mintableSupply, "Mintable supply exceeded!");
        _;}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if(whitelistMintEnabled == true && paused == true){
            require(msg.value >= costWhitelist * _mintAmount, "Insufficient funds!");}
        if(paused == false){
            require(msg.value >= costPublicSale * _mintAmount, "Insufficient funds!");}
        _;}

    modifier genderChangePriceCompliance() {
        require(msg.value >= costGenderChange, "Insufficient funds!");
        _;}

    function setCostWhitelist(uint256 _cost) public onlyOwner {
        costWhitelist = _cost;}

    function setCostPublicSale(uint256 _cost) public onlyOwner {
        costPublicSale = _cost;}

    function mint(uint256 _mintAmount, uint256 _sex) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, 'The contract is paused!');
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        uint256 nftMinted = NFTminted;
        NFTminted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
        for (uint i = 1; i <= _mintAmount; i++) {
            uint256 NFT = nftMinted + i;
            sex[NFT] = _sex;}}

    function mintForAddress(uint256 _mintAmount, address _receiver, uint256 _sex) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        //Minted by Owner without any cost, doesn't count on minted quantity
        uint256 nftMinted = NFTminted;
        NFTminted += _mintAmount;
        _safeMint(_receiver, _mintAmount);
        for (uint i = 1; i <= _mintAmount; i++) {
            uint256 NFT = nftMinted + i;
            sex[NFT] = _sex;}}

    function genderChange(uint256 _sex, uint256 _tokenId) public payable genderChangePriceCompliance() {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require((ownerOf(_tokenId) == address(_msgSender()) || getApproved(_tokenId) == address(_msgSender())),"ERC721A: changer caller is not owner nor approved");
        require(_sex != sex[_tokenId], "Same Sex");
        sex[_tokenId] = _sex;}

    function genderView(uint256 _tokenId) public view returns (string memory _sex) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(sex[_tokenId] == 0){
            _sex = "X";}
        if(sex[_tokenId] == 1){
            _sex = "M";}
        if(sex[_tokenId] == 2){
            _sex = "F";}
        return(_sex);}

    function burn(uint256 tokenId) public {
        _burn(tokenId, true); }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function setUri(uint _tokenId, string memory xUri, string memory mUri, string memory fUri) public onlyOwner {
        uri[_tokenId][0] = xUri;
        uri[_tokenId][1] = mUri;
        uri[_tokenId][2] = fUri;
        edited[_tokenId] = 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return hiddenMetadataUri;}
        if (revealed == true) {
            string memory currentBaseURI;
            if(sex[_tokenId] == 0){
                currentBaseURI = string(abi.encodePacked(xUriPrefix, _tokenId.toString(), uriSuffix));
                if(edited[_tokenId] == 1){
                    currentBaseURI = uri[_tokenId][0];}}
            if(sex[_tokenId] == 1){
                currentBaseURI = string(abi.encodePacked(mUriPrefix, _tokenId.toString(), uriSuffix));
                if(edited[_tokenId] == 1){
                    currentBaseURI = uri[_tokenId][1];}}
            if(sex[_tokenId] == 2){
                currentBaseURI = string(abi.encodePacked(fUriPrefix, _tokenId.toString(), uriSuffix));
                if(edited[_tokenId] == 1){
                    currentBaseURI = uri[_tokenId][2];}}
            return currentBaseURI;}}
    
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;}

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _mUriPrefix, string memory _fUriPrefix, string memory _xUriPrefix) public onlyOwner {
        mUriPrefix = _mUriPrefix;
        fUriPrefix = _fUriPrefix;
        xUriPrefix = _xUriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function setPaused(bool _state) public onlyOwner {
        paused = _state;}

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;}

    function whitelistAddress (address[] memory _addr) public onlyOwner() {
        for (uint i = 0; i < _addr.length; i++) {
            if(whitelisted[_addr[i]] == false){
                whitelisted[_addr[i]] = true;}}}

    function blacklistWhitelisted(address _addr) public onlyOwner() {
        require(whitelisted[_addr], "Account is already Blacklisted");
        whitelisted[_addr] = false;}

    function whitelistMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(whitelisted[_msgSender()], "Account is not in whitelist");
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        NFTminted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);}

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);}
        
    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user 
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) public override virtual{
        require((ownerOf(tokenId) == address(_msgSender()) || getApproved(tokenId) == address(_msgSender())),"ERC721A: rental caller is not owner nor approved");
        require(userOf(tokenId) == address(0),"User already assigned");
        require(expires > block.timestamp, "Expires should be in future");
        UserInfo storage info =  _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId,user,expires);}

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view override virtual returns(address){
        if( uint256(_users[tokenId].expires) >=  block.timestamp){
            return _users[tokenId].user; }
        return address(0);}

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user 
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) public view override virtual returns(uint256){
        return _users[tokenId].expires;}}
    
