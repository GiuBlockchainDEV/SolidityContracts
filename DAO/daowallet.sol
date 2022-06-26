// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ | 

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

interface new_type_IERC20 {
    function transfer(address, uint) external returns (bool);}

interface old_type_IERC20 {
    function transfer(address, uint) external;}

interface IERC721A {
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error ApprovalToCurrentOwner();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;}

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function totalSupply() external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function contractOwner() external view returns (address);}

interface ERC721A__IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}

contract ERC721A is IERC721A {   
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    uint256 private constant BITPOS_NUMBER_MINTED = 64;
    uint256 private constant BITPOS_NUMBER_BURNED = 128;
    uint256 private constant BITPOS_AUX = 192;
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;
    uint256 private constant BITPOS_START_TIMESTAMP = 160;
    uint256 private constant BITMASK_BURNED = 1 << 224;
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;
    uint256 private _currentIndex;
    uint256 private _burnCounter;
    string private _name;
    string private _symbol;
    address _contractOwner;
    
    mapping(uint256 => uint256) private _packedOwnerships;
    mapping(address => uint256) private _packedAddressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, address contractOwner_) {
        _name = name_;
        _symbol = symbol_;
        _contractOwner = contractOwner_;
        _currentIndex = _startTokenId();}
        
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;}
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;}
    function totalSupply() public view override returns (uint256) {
        unchecked {return _currentIndex - _burnCounter - _startTokenId();}}
    function _totalMinted() internal view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();}}
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;}
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;}
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;}
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;}
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;}
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);}
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly {auxCasted := aux}
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;}
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;
        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    if (packed & BITMASK_BURNED == 0) {
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];}
                        return packed;}}}
        revert OwnerQueryForNonexistentToken();}
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;}
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);}
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);}}
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));}
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));}
    function name() public view virtual override returns (string memory) {
        return _name;}
    function symbol() public view virtual override returns (string memory) {
        return _symbol;}
    function contractOwner() public view virtual override returns (address) {
        return _contractOwner;}
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';}
    function _baseURI() internal view virtual returns (string memory) {
        return '';}
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value}}
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value}}
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();
        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();}
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);}
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        return _tokenApprovals[tokenId];}
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);}
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];}
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && _packedOwnerships[tokenId] & BITMASK_BURNED == 0;}
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');}
    function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        _beforeTokenTransfers(address(0), to, startTokenId, quantity);
        unchecked {
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);
            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;
            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();}} 
                while (updatedIndex < end);
                if (_currentIndex != startTokenId) revert();} 
                else {
                do {emit Transfer(address(0), to, updatedIndex++);} while (updatedIndex < end);}
            _currentIndex = updatedIndex;}
        _afterTokenTransfers(address(0), to, startTokenId, quantity);}
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        _beforeTokenTransfers(address(0), to, startTokenId, quantity);
        unchecked {
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);
            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;
            do {emit Transfer(address(0), to, updatedIndex++);} while (updatedIndex < end);
            _currentIndex = updatedIndex;}
        _afterTokenTransfers(address(0), to, startTokenId, quantity);}
    function _transfer(address from, address to, uint256 tokenId) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();
        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();
        _beforeTokenTransfers(from, to, tokenId, 1);
        delete _tokenApprovals[tokenId];
        unchecked {
            --_packedAddressData[from];
            ++_packedAddressData[to]; 
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                if (_packedOwnerships[nextTokenId] == 0) {
                    if (nextTokenId != _currentIndex) {
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;}}}}
        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);}
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);}
    //ERC1238 Standard:
    //  Implementers MUST allow token recipients to burn any token they receive.
    //  Implementers MAY enable token issuers to burn the tokens they issued.
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
        address from = address(uint160(prevOwnershipPacked));
        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from || isApprovedForAll(from, _msgSenderERC721A()) || getApproved(tokenId) == _msgSenderERC721A() || _msgSenderERC721A() == _contractOwner);
            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();}
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        delete _tokenApprovals[tokenId];
        unchecked {
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED | 
                BITMASK_NEXT_INITIALIZED;
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                if (_packedOwnerships[nextTokenId] == 0) {
                    if (nextTokenId != _currentIndex) {
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;}}}}
        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);
        unchecked {_burnCounter++;}}
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;} 
            catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();} 
            else {
                assembly {revert(add(32, reason), mload(reason))}}}}
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;}
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            ptr := add(mload(0x40), 128)
            mstore(0x40, ptr)
            let end := ptr
            for { 
                let temp := value
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)} 
            temp { 
                temp := div(temp, 10)} { 
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))}
            let length := sub(end, ptr)
            ptr := sub(ptr, 32)
            mstore(ptr, length)}}}

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
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;}}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());}
    function owner() public view virtual returns (address) {
        return _owner;}
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;}
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);}}
        
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";}
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;}
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;}
        return string(buffer);}
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";}
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;}
        return toHexString(value, length);}
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;}
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);}
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);}}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);}}
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);}}
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);}}
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);}}
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);}}
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;}}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;}}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;}}}

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
    function updateTimestamp() public {
        //1 day -> 86400 seconds
        lastUpdated = block.timestamp;}
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

    function read_proposal(uint _idproposal) public view returns(string memory, uint, uint, uint, string memory, address, address) {
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
    //MAX MINT AMOUNT
    //PROPOSAL -> 1
    function DAOsetMaxMintAmountPerTx(uint _idproposal) public {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposalPassed[_idproposal] == true, "Proposal not passed");  
        require(proposals[_idproposal].typeproposal == 1, "Wrong function");
        require(proposalExecuted[_idproposal] == false, "Already done");  

        maxMintAmountPerTx = proposals[_idproposal].value;
        
        proposalExecuted[_idproposal] = true;}

    //HIDDEN METADATA
    //PROPOSAL -> 2
    function DAOsetHiddenMetadataUri(uint _idproposal) public onlyOwner {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposalPassed[_idproposal] == true, "Proposal not passed");  
        require(proposals[_idproposal].typeproposal == 2, "Wrong function");
        require(proposalExecuted[_idproposal] == false, "Already done");  

        hiddenMetadataUri = proposals[_idproposal].extraData;
        
        proposalExecuted[_idproposal] = true;}

    //SET URI PREFIX
    //PROPOSAL -> 3
    function DAOsetUriPrefix(uint _idproposal) public onlyOwner {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposalPassed[_idproposal] == true, "Proposal not passed");  
        require(proposals[_idproposal].typeproposal == 3, "Wrong function");
        require(proposalExecuted[_idproposal] == false, "Already done");  

        uriPrefix = proposals[_idproposal].extraData;
        
        proposalExecuted[_idproposal] = true;}

    //SET URI SUFFIX
    //PROPOSAL -> 4
    function DAOsetUriSuffix(uint _idproposal) public onlyOwner {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposalPassed[_idproposal] == true, "Proposal not passed");  
        require(proposals[_idproposal].typeproposal == 4, "Wrong function");
        require(proposalExecuted[_idproposal] == false, "Already done");  

        uriSuffix = proposals[_idproposal].extraData;

        proposalExecuted[_idproposal] = true;}

    //SET PAUSED
    //PROPOSAL -> 5
    function DAOsetPaused(uint _idproposal) public {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended");  
        require(proposalPassed[_idproposal] == true, "Proposal not passed");
        require(proposalExecuted[_idproposal] == false, "Already done");   
        require(proposals[_idproposal].typeproposal == 5, "Wrong function");

        if(proposals[_idproposal].value > 0){
            paused = true;}
        if(proposals[_idproposal].value < 1){
            paused = false;}

        proposalExecuted[_idproposal] = true;}

    //SET REVEALED NFT
    //PROPOSAL -> 6
    function DAOsetRevealed(uint _idproposal) public {
        //Reveal the token URI of the NFTs
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already done"); 
        require(proposals[_idproposal].typeproposal == 6, "Wrong function");

        if(proposals[_idproposal].value > 0){
            revealed = true;}
        if(proposals[_idproposal].value < 1){
            revealed = false;}

        proposalExecuted[_idproposal] = true;}

    //SET MULTIPLIER QUORUM
    //PROPOSAL -> 7
    function DAOsetMultiplierQuorum(uint _idproposal) public {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already done"); 
        require(proposals[_idproposal].typeproposal == 7, "Wrong function");

        multiplier = proposals[_idproposal].value;
        
        proposalExecuted[_idproposal] = true;}

    //MINT FOR AN ADDRESS
    //PROPOSAL -> 8
    function DAOmintForAddress(uint _idproposal) public nonReentrant {
        //Mint new governance NFTs
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(totalSupply() + proposals[_idproposal].value <= maxSupply, "Max supply exceeded!");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already done"); 
        require(proposals[_idproposal].typeproposal == 8, "Wrong function");

        NFTminted += proposals[_idproposal].value;
        _safeMint(proposals[_idproposal].to, proposals[_idproposal].value);
        
        proposalExecuted[_idproposal] = true;}

    //TRANSFER ERC20
    //PROPOSAL -> 9
    function DAOtransferERC20(uint _idproposal) public nonReentrant {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already paid"); 
        require(proposals[_idproposal].typeproposal == 9, "Wrong function");

        new_type_IERC20(proposals[_idproposal].tokenAddr).transfer(proposals[_idproposal].to, proposals[_idproposal].value);
        
        proposalExecuted[_idproposal] = true;}

    //TRANSFER ERC20 OLD
    //PROPOSAL -> 10
    function DAOtransferERC20O(uint _idproposal) public nonReentrant {  
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already paid"); 
        require(proposals[_idproposal].typeproposal == 10, "Wrong function");

        old_type_IERC20(proposals[_idproposal].tokenAddr).transfer(proposals[_idproposal].to, proposals[_idproposal].value);
        
        proposalExecuted[_idproposal] = true;}

    //TRANSFER ETHER
    //PROPOSAL -> 11
    function DAOtransferEther(uint _idproposal) public nonReentrant {
        require(balanceOf(msg.sender) > 0, "Not a member of the DAO");
        require(proposalEnded[_idproposal] == true || proposals[_idproposal].timeend <= block.timestamp, "Proposal not ended"); 
        require(proposalPassed[_idproposal] == true, "Proposal not passed");    
        require(proposalExecuted[_idproposal] == false, "Already paid"); 
        require(proposals[_idproposal].typeproposal == 11, "Wrong function");

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
