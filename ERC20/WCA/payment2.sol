//SPDX-License-Identifier: GPL-3.0
//Giuliano Neroni DEV

pragma solidity ^0.8.16;

import "./ownable.sol";
import "./string.sol";

contract tx_mapping is Ownable{
    
    struct wallet_data {
        uint256 wallet_id;
        uint8 kyc_state;         //stato del kyc 0 non effettuato 1 pending 2 passed 3 not passed
        uint256 tx_done;
        string usdt_spent;
        string last_update;}

    struct wallet_tx{
        uint256 id_db;
        string hash_tx;
        uint256 blockchain_id;
        string token_id;
        string amount;
        string hash_cnvx;
        string usdt_spent;
        uint8 tx_state;
        uint256 last_update;}

    mapping(address => mapping(uint => wallet_tx)) public storage_tx;
    mapping(address => uint) public tx_done;

    function store_tx(address _wallet_address, uint256 _id_db, string memory _hash_tx, uint256 _blockchain_id, string memory _token_id, string memory _amount) public onlyOwner {  
        uint i = tx_done[_wallet_address];
        tx_done[_wallet_address] += 1;
        storage_tx[_wallet_address][i].id_db = _id_db;
        storage_tx[_wallet_address][i].hash_tx = _hash_tx;
        storage_tx[_wallet_address][i].blockchain_id = _blockchain_id;
        storage_tx[_wallet_address][i].token_id = _token_id;
        storage_tx[_wallet_address][i].amount = _amount;
        storage_tx[_wallet_address][i].tx_state = 0;
        storage_tx[_wallet_address][i].last_update = block.timestamp;}
            
    function update_cnvx(address _wallet_address, uint256 _tx_done, string memory _hash_cnvx, string memory _usdt_spent) public onlyOwner {
        storage_tx[_wallet_address][_tx_done].hash_cnvx = _hash_cnvx;
        storage_tx[_wallet_address][_tx_done].usdt_spent = _usdt_spent;
        storage_tx[_wallet_address][_tx_done].tx_state = 3;
        storage_tx[_wallet_address][_tx_done].last_update = block.timestamp;}


    mapping(address => wallet_data) public wallet;
    mapping (address => bool) public registered;
    mapping(address => string[]) public scores;



    address[] public client;

    uint256 id_tx;

    uint public total_tx;
    uint public total_wallet;
    
    function purchase(address _address_wallet, string memory _hash_tx, string memory _blockchain_id, string memory _amount, string memory _token_id) public onlyOwner {
        id_tx += 1;
        total_tx = id_tx;
        //store_tx(_address_wallet, _hash_tx, _blockchain_id, _amount, _token_id);

        if(registered[_address_wallet] == false){
            register_addr(_address_wallet);}}    
   
      
    function register_addr(address _address_wallet) public onlyOwner() {
        require(!registered[_address_wallet], "Account is already registered");

        registered[_address_wallet] = true;
        total_wallet += 1;
        wallet[_address_wallet].wallet_id = total_wallet;
        client.push(_address_wallet);}

    function update_addr(address _address_wallet, uint8 _kyc_state, uint256 _tx_done, string memory _usdt_spent, string memory _last_update) public onlyOwner() {
        require(registered[_address_wallet], "Account is not registered");

        wallet[_address_wallet].kyc_state = _kyc_state;
        wallet[_address_wallet].tx_done = _tx_done;
        wallet[_address_wallet].usdt_spent = _usdt_spent;
        wallet[_address_wallet].last_update = _last_update;}}
