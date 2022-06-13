// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract price_scan {
    mapping(address => address) public address_stable;
    mapping(address => uint) public decimals_stable;
    mapping(address => uint) public price;
    mapping(address => address) public router;
    mapping(address => address) public path_1;
    mapping(address => address) public path_2;

    address[] public keys;
    address public _owner;

    constructor(address deployer) {
        _owner = deployer;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function set(address _addr, address _stable, uint _dec, uint _price, address _router, address _path_1, address _path_2) external onlyOwner() {
        address_stable[_addr] = _stable;
        decimals_stable[_addr] = _dec;
        price[_addr] = _price;
        router[_addr] = _router;
        path_1[_addr] = _path_1;
        path_2[_addr] = _path_2;
        keys.push(_addr);
    }

    function get(uint _index) external view returns (address, uint, uint, address, address, address) {
        address key = keys[_index];
        return (address_stable[key], decimals_stable[key], price[key], router[key], path_1[key], path_2[key]);
    }
}
