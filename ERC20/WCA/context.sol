// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}}
