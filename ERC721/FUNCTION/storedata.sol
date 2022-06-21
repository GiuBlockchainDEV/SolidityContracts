// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract Storedata {

    mapping (address => mapping (uint => string)) id_data;
    mapping (address => uint) public archived;
    uint private archived_data;


    function setData(address _address, string memory _key) public {
        archived[_address] += 1;
        archived_data = archived[msg.sender];
        id_data[_address][archived_data] = _key;}

    function getData(address _address, uint _id) public view returns (string memory) {
        return(id_data[_address][_id]);}}
