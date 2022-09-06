//SPDX-License-Identifier: GPL-3.0
//Giuliano Neroni DEV

pragma solidity ^0.8.16;

import "./ownable.sol";
import "./string.sol";

contract tx_mapping is Ownable{
    
    struct tx_stored {
        uint256 tx_done;
        string hash_tx;         //hash delle transazioni
        string blockchain_id;   //blockchain delle transazioni
        string amount;          //importi inviati
        string token_id;        //token usati
        string usdt_spent;
        string tx_state;
        string hash_cnv;
        string id_db;}

    struct wallet_data {
        uint256 wallet_id;
        uint8 kyc_state;         //stato del kyc 0 non effettuato 1 pending 2 passed 3 not passed
        uint256 tx_done;
        string usdt_spent;
        string last_update;}

    struct cnvx{
        string usdt_spent;
        string hash_tx;
        string datetime;}

    mapping(address => cnvx[]) public storage_cnvx;
    mapping(address => uint) public cnvx_done;

    function add_cnvx(address _wallet_address, string memory _usdt_spent, string memory _hash_tx, string memory _datetime) public {
        cnvx_done[_wallet_address] += 1;
        storage_cnvx[_wallet_address].push(cnvx(_usdt_spent, _hash_tx, _datetime));}



    mapping(address => tx_stored) public stored;
    mapping(address => wallet_data) public wallet;
    mapping (address => bool) public registered;


    address[] public client;

    uint256 id_tx;

    uint public total_tx;
    uint public total_wallet;
    
    function purchase(address _address_wallet, string memory _hash_tx, string memory _blockchain_id, string memory _amount, string memory _token_id) public onlyOwner {
        id_tx += 1;
        total_tx = id_tx;
        store_tx(_address_wallet, _hash_tx, _blockchain_id, _amount, _token_id);

        if(registered[_address_wallet] == false){
            register_addr(_address_wallet);}}

    function store_tx(address _address_wallet, string memory _hash_tx, string memory _blockchain_id, string memory _amount, string memory _token_id) private onlyOwner {  
        uint256 tx_done;
        string memory hash_tx_add;
        string memory blockchain_id_add;
        string memory amount_add;
        string memory token_id_add;

        tx_done = stored[_address_wallet].tx_done;
        stored[_address_wallet].tx_done += 1;

        if(tx_done == 0){
            stored[_address_wallet].hash_tx = _hash_tx;
            stored[_address_wallet].blockchain_id = _blockchain_id;
            stored[_address_wallet].amount = _amount;
            stored[_address_wallet].token_id = _token_id;}

        if(tx_done > 0){
            hash_tx_add = stored[_address_wallet].hash_tx;
            blockchain_id_add = stored[_address_wallet].blockchain_id;
            amount_add = stored[_address_wallet].amount;
            token_id_add = stored[_address_wallet].token_id;

            stored[_address_wallet].hash_tx = string(abi.encodePacked(hash_tx_add, "/", _hash_tx));
            stored[_address_wallet].blockchain_id = string(abi.encodePacked(blockchain_id_add, "/", _blockchain_id));
            stored[_address_wallet].amount = string(abi.encodePacked(amount_add, "/", _amount));
            stored[_address_wallet].token_id = string(abi.encodePacked(token_id_add, "/", _token_id));}}

    function update_tx(address _address_wallet, string memory _usdt_spent, string memory _tx_state, string memory _hash_cnv, string memory _id_db) public onlyOwner() {
        
        stored[_address_wallet].usdt_spent = _usdt_spent;
        stored[_address_wallet].tx_state = _tx_state;
        stored[_address_wallet].hash_cnv = _hash_cnv;
        stored[_address_wallet].id_db = _id_db;}
      
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
