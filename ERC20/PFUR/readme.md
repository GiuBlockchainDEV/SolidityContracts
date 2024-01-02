Constructor: Questa funzione inizializza il contratto. Non contiene codice specifico, quindi esegue solo le operazioni standard di inizializzazione.


setTokenAddress(address _token): 
Imposta l'indirizzo del token ERC20 utilizzato nella pre-vendita. Solo il proprietario del contratto può chiamare questa funzione. In questa funzione va inserito l’indirizzo del token PFUR o di qualunque altro token venga utilizzato per il test


setPulseToUsdRate(uint256 _rate): Aggiorna il tasso di cambio tra Pulse e USD direttamente da https://www.coingecko.com/it/monete/pulsechain inserendo il valore come intero (esempio 0,00006039 inserisci 6039) . Solo il proprietario può modificare questo valore.


setListUsdRate(uint256 _privateDecimals, uint256 _ratePrivate, uint256 _publicDecimals, uint256 _ratePublic): Imposta i tassi di cambio e i decimali per il rate di cambio relativo alla whitelist privata e pubblica. Solo il proprietario può usare questa funzione. Il valore dei decimali è da considerare quanto sposti la virgola, esempio 2.75 public decimals = 2 rate public = 275


setRegistrationFee(uint256 _amount, uint256 _decimal): Stabilisce una tassa di registrazione per la whitelist pubblica, consentendo al proprietario di modificare l'importo e la precisione decimale. Esempio 100 pulse corrispondono ad amount = 100 e decimal = 18. Nel caso volessi mettere numeri decimali amounti la parte intera spostando i decimali di quanti numeri aggiungi alla parte intera per esempio 100.1 amount = 1001 decimal = 19.


registerForPublicWhitelist(address _address): Consente agli utenti di registrarsi alla whitelist pubblica, pagando la tassa di registrazione. Ha meccanismi per evitare la reentrancy e verifica se il limite di registrazione è stato raggiunto. il rate di cambio viene preso in base a se l’utente viene inserito dall’owner o meno, e nel caso non venga inserito dall’owner si è tenuti a pagare anche la registration fee. I massimi utenti che si possono registrati (non tenendo conto di quelli inseriti dall’owner) sono 275


startPresale(bool _state): Attiva o disattiva la pre-vendita permettendo la funzione buyTokens() . Questa azione può essere eseguita solo dal proprietario del contratto.


enableClaim(bool _state, uint256 _days): Abilita o disabilita la possibilità per gli utenti di richiedere i token acquistati, impostando anche la durata della pre-vendita. Prima di fare questo devono essere inviati i PFUR al contratto.


enableAll(bool _state): Abilita o disabilita la vendita di token a tutti gli utenti, non solo a quelli nella whitelist.


setDuration(uint256 _days): Imposta la durata della pre-vendita in giorni. Solo il proprietario può utilizzare questa funzione.


buyTokens(): Consente agli utenti di acquistare token attraverso i PULSE durante la pre-vendita. Calcola l'importo dei token in base al valore inviato e ai tassi di cambio applicabili.


calculateAmount(uint256 _amount, uint256 _decimals): Calcola la quantità di token che possono essere acquistati per un dato importo e decimali. È una funzione di visualizzazione.


claimTokens(): Permette agli utenti di richiedere i token che hanno acquistato una volta che la pre-vendita è terminata e la richiesta è stata abilitata.


withdraw(address _to): Consente al proprietario di prelevare il saldo in PULSE del contratto ed inviarlo all’indirizzo da lui scelto


transferAnyNewERC20Token(address _tokenAddr, address _to, uint _amount) transferAnyOldERC20Token(address _tokenAddr, address _to, uint _amount): 
Entrambe le funzioni permettono al proprietario di trasferire token ERC20 da questo contratto ad un altro indirizzo. La differenza tra le due funzioni sta nell'interfaccia del token ERC20 (nuova o vecchia) che viene utilizzata.
