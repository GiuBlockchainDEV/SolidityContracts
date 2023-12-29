// SPDX-License-Identifier: MIT
/*
┏━━━┓┏━━━┓┓┃┏┓━━━┓
┃┏━┓┃┃┏━━┛┃┃┃┃┏━┓┃
┃┗━┛┃┃┗━━┓┃┃┃┃┗━┛┃
┃┏━━┛┃┏━━┛┃┃┃┃┏┓┏┛
┃┃┃┃┃┛┗┓┃┃┗━┛┃┃┃┗┓
┗┛┃┃┃━━┛┃┃━━━┛┛┗━┛
┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃
┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃
*/

pragma solidity ^0.8.18;

import "./interface.sol";

contract ERC20Presale is Ownable, ReentrancyGuard {
    IERC20 public token;
    uint256 public end;

    uint256 public tokensSold;
    uint256 public constant maximumSellable = 5 * (10 ** 9) * (10 ** 18);

    bool public started;
    bool public claimEnabled;
    bool public enabledForAll;

    mapping(address => uint256) public tokensToClaim;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public discounted;
    
    uint256 public privateDecimalsRate = 10 ** 1;
    uint256 public privateWhitelistRate = 25; 

    uint256 public publicDecimalsRate = 10 ** 2;
    uint256 public publicWhitelistRate = 275; 

    uint256 public constant decimalsDifference = 10 ** 8;
    uint256 public pulseToUsdRate = 6415; 
     

    uint256 public registrationFee = 1 * (10 ** 18);
    uint256 public constant MAX_PUBLIC_WHITELIST_REGISTRATIONS = 299;
    uint256 public publicWhitelistRegistrations;

    constructor() {
    }

    //Set the address of the PFUR contract
    function setTokenAddress(address _token) public onlyOwner {
        token = IERC20(_token);
    }
        
    //The value to 8 decimal places from https://www.coingecko.com/it/monete/pulsechain is taken daily and entered as an integer part
    function setPulseToUsdRate(uint256 _rate) public onlyOwner {
        pulseToUsdRate = _rate; 
    }

    function setListUsdRate(uint256  _privateDecimals, uint256 _ratePrivate, uint256 _publicDecimals, uint256 _ratePublic) public onlyOwner {
        privateWhitelistRate = _ratePrivate;
        privateDecimalsRate = 10 ** _privateDecimals;
        publicWhitelistRate = _ratePublic;
        publicDecimalsRate = _publicDecimals;
    }

    function setRegistrationFee(uint256 _amount, uint256 _decimal) public onlyOwner {
        registrationFee = _amount * (10 ** _decimal);
    }

    function registerForPublicWhitelist() external payable nonReentrant {
        require(!whitelist[msg.sender], "Already registered in the whitelist");

        if (msg.sender == owner()){
            whitelist[msg.sender] = true;
            discounted[msg.sender] = true;
        }
        else {
            require(publicWhitelistRegistrations < MAX_PUBLIC_WHITELIST_REGISTRATIONS, "Registration limit reached");
            require(msg.value == registrationFee, "Incorrect registration amount");
            whitelist[msg.sender] = true;
            publicWhitelistRegistrations++;
        }
    }

    //Set true to activate it, dafault value is false
    function startPresale(bool _state) public onlyOwner {
        started = _state;
    }

    //Set true to activate it, dafault value is false
    function enableClaim(bool _state, uint256 _days) public onlyOwner {
        setDuration(_days);
        claimEnabled = _state;
    }

    function enableAll(bool _state) public onlyOwner {
        enabledForAll = _state;
    }

    function setDuration(uint256 _days) public onlyOwner returns(uint256) {
        end = block.timestamp + (_days * 86400);
        return block.timestamp;
    }

    function buyTokens() external payable nonReentrant {
        require(started, "Presale not started");
        require(block.timestamp < end, "Presale finished");
        require(msg.value > 0, "You have to send PLS");

        uint256 rate;
        uint256 decimal;

        if (!enabledForAll) {
            require(whitelist[msg.sender], "Non registered user");

            if (discounted[msg.sender]) {
                rate = privateWhitelistRate;
                decimal = privateDecimalsRate;
            }
            
            else{
                rate = publicWhitelistRate;
                decimal = publicDecimalsRate;
            }   
        }

        else {
            rate = publicWhitelistRate;
            decimal = publicDecimalsRate;
        }

        uint256 tokenAmount = msg.value * pulseToUsdRate / decimalsDifference;
        tokenAmount = tokenAmount / rate / decimal;
        require(tokensSold + tokenAmount <= maximumSellable, "Sales limit exceeded");

        tokensSold += tokenAmount;
        tokensToClaim[msg.sender] += tokenAmount;
    }

    function calculateAmount(uint256 _amount, uint256 _decimals) public view returns (uint256) {
        uint256 _token = _amount * pulseToUsdRate * (10 ** _decimals);
        _token = _token / decimalsDifference;
        _token = _token / publicWhitelistRate / publicDecimalsRate;
        return _token;   
    }

    function claimTokens() external nonReentrant {
        require(claimEnabled, "Claim not yet enabled");
        uint256 amount = tokensToClaim[msg.sender];
        require(amount > 0, "No tokens to redeem");

        tokensToClaim[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }

    function withdraw(address _to) public onlyOwner nonReentrant {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(_to).call{value: address(this).balance}('');
        require(os);
    }

    function transferAnyNewERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(NewIERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");
    }

    function transferAnyOldERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        OldIERC20(_tokenAddr).transfer(_to, _amount);
    }
}
