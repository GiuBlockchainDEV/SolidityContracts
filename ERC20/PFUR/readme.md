# ERC20Presale Smart Contract

## Introduzione
Il contratto `ERC20Presale` è progettato per gestire una fase di presale di token ERC20. Permette agli utenti di registrarsi, comprare token e reclamare i loro token dopo la vendita.

## Funzioni

### Configurazione Iniziale
- `constructor()`: Inizializza il contratto.
- `setTokenAddress(address _token)`: Imposta l'indirizzo del token ERC20 che verrà venduto.
- `setMinPulse(uint256 _amount, uint256 _decimal)`: Imposta il minimo importo di Pulse accettato per l'acquisto.
- `setMaxPulse(uint256 _amount, uint256 _decimal)`: Imposta il massimo importo di Pulse accettato per l'acquisto.
- `setMaximumSellable(uint256 _amount, uint256 _decimal)`: Imposta il massimo numero di token che possono essere venduti.
- `setRegistrationFee(uint256 _amount, uint256 _decimal)`: Imposta la commissione di registrazione per la whitelist pubblica.
- `setVault(address payable _vault)`: Imposta l'indirizzo del vault dove verranno depositati i fondi raccolti.
- `setListUsdRate(...)`: Imposta il tasso di cambio per la conversione tra Pulse e Furio.

### Gestione Whitelist e Acquisto
- `registerForPublicWhitelist(address _address)`: Permette la registrazione alla whitelist pubblica.
- `setPresaleState(uint256 _phase)`: Imposta la fase corrente della presale.
- `buyTokens()`: Permette agli utenti di comprare token durante la presale.

### Reclamo e Ritiro
- `claimTokens()`: Permette agli utenti di reclamare i loro token dopo la fine della presale.
- `withdraw(address _to)`: Permette al proprietario di ritirare i fondi raccolti.
- `transferAnyNewERC20Token(...)`: Permette il trasferimento di nuovi token ERC20.
- `transferAnyOldERC20Token(...)`: Permette il trasferimento di vecchi token ERC20.

## Utilizzo

### Registrazione per la Whitelist
Gli utenti possono registrarsi alla whitelist pubblica invocando `registerForPublicWhitelist` con il loro indirizzo.

### Acquisto di Token
Durante la fase di acquisto, gli utenti possono invocare `buyTokens` per acquistare token in base al tasso di cambio attuale.

### Reclamo Token
Dopo la fine della presale, gli utenti possono reclamare i loro token invocando `claimTokens`.

### Ritiro dei Fondi
Il proprietario del contratto può ritirare i fondi raccolti e gestire i token ERC20 tramite le funzioni `withdraw`, `transferAnyNewERC20Token` e `transferAnyOldERC20Token`.

## Fasi della Presale
- Fase 0: Whitelist (Solo Proprietario)
- Fase 1: Whitelist (Domanda Pubblica)
- Fase 2: Acquisto (Utenti Whitelist)
- Fase 3: Vendita Aperta
- Fase 4: Reclamo
- Fase 5: Stop Vendita
