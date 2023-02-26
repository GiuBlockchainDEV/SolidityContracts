pragma solidity ^0.8.0;

contract Authenticator {
    
    mapping(address => bytes32) private users;
    mapping(address => uint) private lastOTPTime;
    mapping(address => mapping(uint => uint)) private used;
    
    function register() public {
        require(users[msg.sender] == bytes32(0), "Utente gia registrato.");
        bytes32 userSeed = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        users[msg.sender] = userSeed;
    }
    
    function authenticate(uint _otp) public returns (bool) {
        bytes32 userSeed = users[msg.sender];
        require(userSeed != bytes32(0), "Utente non registrato.");
        uint lastTime = lastOTPTime[msg.sender];
        require(block.timestamp - lastTime <= 30, "Registra nuovo OTP");
        require(used[msg.sender][lastTime] == 0, "Codice usato");
        bool auth;
        uint otp = uint(keccak256(abi.encodePacked(lastTime, userSeed))) % 1000000;
        if(_otp == otp){
            auth = true;
            used[msg.sender][lastTime] = 1;
        }
        else{
            auth = false;
        }
        return (auth);
    }
    
    function getOTP() public returns (uint) {
        bytes32 userSeed = users[msg.sender];
        require(userSeed != bytes32(0), "Utente non registrato.");
        uint lastTime = lastOTPTime[msg.sender];
        require(block.timestamp - lastTime >= 30, "OTP gia generato.");
        uint otp = uint(keccak256(abi.encodePacked(block.timestamp, userSeed))) % 1000000;
        lastOTPTime[msg.sender] = block.timestamp;
        return otp;
    }
}
