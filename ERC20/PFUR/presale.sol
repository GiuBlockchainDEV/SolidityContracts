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

    uint256 public tokensSold;
    uint256 public constant maximumSellable = 5 * (10 ** 9) * (10 ** 18);

    uint256 public presalePhase;

    mapping(address => uint256) public tokensToClaim;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public discounted;
    
    uint256 public privateDecimalsRate = 10 ** 1;
    uint256 public privateWhitelistRate = 25; 

    uint256 public publicDecimalsRate = 10 ** 2;
    uint256 public publicWhitelistRate = 275; 

    uint256 public constant decimalsDifference = 10 ** 8;
    uint256 public pulseToUsdRate = 6415; 
     

    uint256 public registrationFee = 1;
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
        publicDecimalsRate = 10 ** _publicDecimals;
    }

    function setRegistrationFee(uint256 _amount, uint256 _decimal) public onlyOwner {
        registrationFee = _amount * (10 ** _decimal);
    }

    function registerForPublicWhitelist(address _address) external payable nonReentrant {
        require(!whitelist[_address], "Already registered in the whitelist");

        if (msg.sender == owner()){
            whitelist[_address] = true;
            discounted[_address] = true;
        }
        else {
            require(presalePhase == 1, "It is not possible to register at this time");
            require(publicWhitelistRegistrations < MAX_PUBLIC_WHITELIST_REGISTRATIONS, "Registration limit reached");
            require(msg.value == registrationFee, "Incorrect registration amount");
            whitelist[_address] = true;
            publicWhitelistRegistrations++;
        }
    }

    //Phase 0 Whitelist -> Sole Proprietor
    //Phase 1 Whitelist -> Public Demand
    //Stage 2 Buy -> All Whitelist users
    //Stage 3 Open Sale
    //Stage 4 Claim
    //Stage 5 Stop Sale

    //Set true to activate it, dafault value is false
    function setPresaleState(uint256 _phase) public onlyOwner {
        presalePhase = _phase;
    } 

    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "You have to send PLS");
        require(presalePhase > 1 && presalePhase < 5, "It is not possible to purchase tokens at this time");

        uint256 rate;
        uint256 decimal;

        if (presalePhase < 3) {
            require(whitelist[msg.sender], "Not registered user");

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
        require(presalePhase == 4, "Claim not yet enabled");
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
