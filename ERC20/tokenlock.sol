pragma solidity ^0.6.0;

// In questo contratto, viene definito un contratto TokenLock che fa riferimento a un contratto Token esistente. 
// Il contratto TokenLock offre due funzioni: lock() per bloccare i token per un determinato periodo di tempo, e unlock() per sbloccare i token 
// quando il periodo di blocco è scaduto.
// Per utilizzare il contratto, è necessario fornire l'indirizzo del contratto Token esistente al momento della creazione del contratto TokenLock. 
// In seguito, gli utenti possono utilizzare le funzioni lock() e unlock() per bloccare e sbloccare i token come desiderato.

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);}

contract TokenLock {
    // Riferimento al contratto del token
    IERC20 public token;

    // Mappatura degli equilibri bloccati degli indirizzi
    mapping (address => uint256) public lockedBalanceOf;

    // Mappatura dei tempi di sblocco degli indirizzi
    mapping (address => uint256) public unlockAt;

    // Costruttore del contratto
    constructor(address _tokenAddress) public {
        // Imposta il riferimento al contratto del token
        token = IERC20(_tokenAddress);
    }

    // Funzione di blocco dei token
    function lock(uint256 _value, uint256 _duration) public {
        // Controlla che il mittente abbia un equilibrio sufficiente
        require(token.balanceOf(msg.sender) >= _value, "Saldo insufficiente");

        // Calcola la data di sblocco
        uint256 unlockAtTime = now + _duration;

        // Trasferisci i token dall'indirizzo del mittente all'indirizzo del contratto
        token.transfer(address(this), _value);

        // Aggiorna gli equilibri e i tempi di sblocco
        lockedBalanceOf[msg.sender] += _value;
        unlockAt[msg.sender] = unlockAtTime;
    }

    // Funzione di sblocco dei token
    function unlock() public {
        // Controlla che i token siano sbloccabili
        require(now >= unlockAt[msg.sender], "I token non possono ancora essere sbloccati");

        // Trasferisci i token dall'indirizzo del contratto all'indirizzo del mittente
        token.transfer(msg.sender, lockedBalanceOf[msg.sender]);

        // Azzera gli equilibri e i tempi di sblocco
        lockedBalanceOf[msg.sender] = 0;
        unlockAt[msg.sender] = 0;
    }
}
