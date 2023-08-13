// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
                                  
interface IERC721A {

    // The caller must own the token or be an approved operator
    error ApprovalCallerNotOwnerNorApproved();

    //The token does not exist
    error ApprovalQueryForNonexistentToken();

    //The caller cannot approve to their own address
    error ApproveToCaller();

    //The caller cannot approve to the current owner
    error ApprovalToCurrentOwner();

    //Cannot query the balance for the zero address
    error BalanceQueryForZeroAddress();

    //Cannot mint to the zero address
    error MintToZeroAddress();

    //The quantity of tokens minted must be more than zero
    error MintZeroQuantity();

    //The token does not exist
    error OwnerQueryForNonexistentToken();

    //The caller must own the token or be an approved operator.
    error TransferCallerNotOwnerNorApproved();

    ///The token must be owned by `from`
    error TransferFromIncorrectOwner();

    //Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    //Cannot transfer to the zero address
    error TransferToZeroAddress();

    //The token does not exist
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;}

    //Returns the total amount of tokens stored by the contract
    //Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens
    function totalSupply() external view returns (uint256);

    //Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    //Emitted when `tokenId` token is transferred from `from` to `to`
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    //Emitted when `owner` enables `approved` to manage the `tokenId` token
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    //Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //Returns the number of tokens in `owner` account
    function balanceOf(address owner) external view returns (uint256 balance);

    //Returns the owner of the `tokenId` token
    function ownerOf(uint256 tokenId) external view returns (address owner);

    //Safely transfers `tokenId` token from `from` to `to`
    //Requirements: `from` cannot be the zero address
    //              `to` cannot be the zero address
    //              `tokenId` token must exist and be owned by `from`
    //              If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}
    //              If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    //Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients are aware of the ERC721 protocol to prevent tokens from being forever locked.
    //Requirements: `from` cannot be the zero address.
    //              `to` cannot be the zero address.
    //              `tokenId` token must exist and be owned by `from`
    //              If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}
    //              If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    //Transfers `tokenId` token from `from` to `to`
    //Requirements: `from` cannot be the zero address
    //              `to` cannot be the zero address
    //              `tokenId` token must be owned by `from`
    //              If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}
    function transferFrom(address from, address to, uint256 tokenId) external;

    //Gives permission to `to` to transfer `tokenId` token to another account
    function approve(address to, uint256 tokenId) external;

    //Approve or remove `operator` as an operator for the caller
    //Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller
    //Requirements: The `operator` cannot be the caller.
    function setApprovalForAll(address operator, bool _approved) external;

    //Returns the account approved for `tokenId` token.
    //Requirements: `tokenId` must exist
    function getApproved(uint256 tokenId) external view returns (address operator);

    //Returns if the `operator` is allowed to manage all of the assets of `owner`
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    //Returns the token collection name
    function name() external view returns (string memory);

    //Returns the token collection symbol
    function symbol() external view returns (string memory);

    //Returns the Uniform Resource Identifier (URI) for `tokenId` token
    function tokenURI(uint256 tokenId) external view returns (string memory);}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface ERC721A__IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}

interface STAKE721 {
    function stakeNFT(address caller, address contractAddress, uint256 tokenId, uint256 value) external returns (bool);
}

