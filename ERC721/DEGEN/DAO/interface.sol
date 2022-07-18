// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface new_type_IERC20 {
    function transfer(address, uint) external returns (bool);}

interface old_type_IERC20 {
    function transfer(address, uint) external;}

interface IERC721A {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);}

interface ERC721A__IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}
