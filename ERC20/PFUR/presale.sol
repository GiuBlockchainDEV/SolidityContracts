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
    address payable public vault;

    uint256 public tokensSold;
    uint256 public maximumSellable = 5 * (10 ** 9) * (10 ** 18);

    uint256 public presalePhase;

    mapping(address => uint256) public tokensToClaim;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public discounted;
    mapping(address => uint256) public pulseUsed;

    bool public privategto;
    uint256 public privateDecimalsRate = 0;
    uint256 public privateWhitelistRate = 19825; //2.5$

    bool public publicgto;
    uint256 public publicDecimalsRate = 0;
    uint256 public publicWhitelistRate = 21815; //2.75$ 

    uint256 public registrationFee = 1;
    uint256 public MAX_PUBLIC_WHITELIST_REGISTRATIONS = 299;
    uint256 public maxPulse = 30000000 * (10**18);
    uint256 public minPulse = 10000 * (10**18);
    uint256 public publicWhitelistRegistrations;

    constructor() {
    }

    //Set the address of the PFUR contract
    function setTokenAddress(address _token) public onlyOwner {
        token = IERC20(_token);
    }
        
    function setMinPulse(uint256 _amount, uint256 _decimal) public onlyOwner {
        minPulse = _amount * (10 ** _decimal);
    }

    function setMaxPulse(uint256 _amount, uint256 _decimal) public onlyOwner {
        maxPulse = _amount * (10 ** _decimal);
    }

    function setMaximumSellable(uint256 _amount, uint256 _decimal) public onlyOwner {
        maximumSellable = _amount * (10 ** _decimal);
    }

    function setRegistrationFee(uint256 _amount, uint256 _decimal) public onlyOwner {
        registrationFee = _amount * (10 ** _decimal);
    }

    function setVault(address payable _vault) public onlyOwner {
        vault = _vault;
    }

    function setMaxUser(uint256 _user) public onlyOwner {
        MAX_PUBLIC_WHITELIST_REGISTRATIONS = _user;
    }

    //From https://www.coingecko.com/it/monete/pulsechain 
    //Get the pulse value corresponding in $ to the desired amount for both public and private
    //GTO true -> mul | GTO false -> div
    function setListUsdRate(bool _privategto, uint256  _privateDecimals, uint256 _ratePrivate, bool _publicgto, uint256 _publicDecimals, uint256 _ratePublic) public onlyOwner {
        privategto = _privategto;
        privateWhitelistRate = _ratePrivate;
        privateDecimalsRate = _privateDecimals;
        
        publicgto = _publicgto;
        publicWhitelistRate = _ratePublic;
        publicDecimalsRate = _publicDecimals;
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
            vault.transfer(msg.value);
        }
    }

    //Phase 0 Whitelist -> Sole Proprietor
    //Phase 1 Whitelist -> Public Demand
    //Stage 2 Buy -> All Whitelist users
    //Stage 3 Open Sale
    //Stage 4 Claim
    //Stage 5 Stop Sale
    function setPresaleState(uint256 _phase) public onlyOwner {
        presalePhase = _phase;
    } 

    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "You have to send PLS");
        require(presalePhase > 1 && presalePhase < 5, "It is not possible to purchase tokens at this time");
        
        uint256 _rate;
        uint256 _decimal;
        uint256 _amount = msg.value;
        uint256 _level;

        require((_amount >= minPulse) || ((_amount + pulseUsed[msg.sender]) >= minPulse), "Minimum not reached");
        require((_amount + pulseUsed[msg.sender]) <= maxPulse, "Maximum reached");

        if (presalePhase < 3) {
            require(whitelist[msg.sender], "Not registered user");

            if (discounted[msg.sender]) {
                _rate = privateWhitelistRate;
                _decimal = privateDecimalsRate;
                _level = 0;
            }
            
            else{
                _rate = publicWhitelistRate;
                _decimal = publicDecimalsRate;
                _level = 1;
            }   
        }

        else {

            if (discounted[msg.sender]) {
                _rate = privateWhitelistRate;
                _decimal = privateDecimalsRate;
                _level = 0;
            }
            
            else{
                _rate = publicWhitelistRate;
                _decimal = publicDecimalsRate;
                _level = 1;
            }   
        }

        uint256 _furioAmount = calculatePulseFurioAmountWei(_amount, _level);
        require(tokensSold + _furioAmount <= maximumSellable, "Sales limit exceeded");
        tokensSold += _furioAmount;
        pulseUsed[msg.sender] += _amount;
        tokensToClaim[msg.sender] += _furioAmount;
        vault.transfer(msg.value);
    }

    function calculateFurio(uint256 _amountPulse, uint256 _decimalsPulse, uint256 _levelWhitelist) public view returns (uint256) {
        uint256 _pulseAmountWei = _amountPulse * (10 ** _decimalsPulse);  
        uint256 _rate;
        uint256 _decimalsRate;
        bool _gto;
        uint256 _pulseFurioAmount;

        if (_levelWhitelist == 0){
            _rate = privateWhitelistRate;
            _decimalsRate = privateDecimalsRate;
            _gto = privategto;
        }
        
        else {
            _rate = publicWhitelistRate;
            _decimalsRate = publicDecimalsRate;
            _gto = publicgto;
        }

        if (_gto) {
            _pulseFurioAmount = _pulseAmountWei * _rate;
        } 

        else {
            _pulseFurioAmount = _pulseAmountWei / _rate ;
        }
        
         _pulseFurioAmount = _pulseFurioAmount / (10 ** _decimalsRate);
        return _pulseFurioAmount;
    }


    function calculatePulseFurioAmountWei(uint256 _pulseAmountWei, uint256 _levelWhitelist) public view returns (uint256) {
        uint256 _rate;
        uint256 _decimalsRate;
        bool _gto;
        uint256 _pulseFurioAmount;

        if (_levelWhitelist == 0){
            _rate = privateWhitelistRate;
            _decimalsRate = privateDecimalsRate;
            _gto = privategto;
        }
        
        else {
            _rate = publicWhitelistRate;
            _decimalsRate = publicDecimalsRate;
            _gto = publicgto;
        }
        
        if (_gto) {
            _pulseFurioAmount = _pulseAmountWei * _rate;
        } 

        else {
            _pulseFurioAmount = _pulseAmountWei / _rate ;
        }
        
         _pulseFurioAmount = _pulseFurioAmount / (10 ** _decimalsRate);
        return _pulseFurioAmount;
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
