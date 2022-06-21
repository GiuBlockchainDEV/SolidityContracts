// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract Whitelist {
    mapping (address => bool) public userAddr;

    function whitelistAddress (address[] memory users) public {
        for (uint i = 0; i < users.length; i++) {
            if(userAddr[users[i]] == false){
                userAddr[users[i]] = true;}}}}
