# ShardNFT Frontend Interface

Questa è un'implementazione frontend per il contratto ShardNFT utilizzando React e Wagmi per l'interazione con la blockchain Ethereum.

## Sommario

- [Configurazione iniziale](#configurazione-iniziale)
- [Variabili in lettura](#variabili-in-lettura)
- [Funzioni di lettura](#funzioni-di-lettura)
- [Funzioni di scrittura](#funzioni-di-scrittura)
- [Funzioni amministrative](#funzioni-amministrative)

## Configurazione iniziale

Per iniziare, configura Wagmi nel tuo progetto React:

```javascript
import { createConfig, configureChains, mainnet } from 'wagmi'
import { publicProvider } from 'wagmi/providers/public'
import { MetaMaskConnector } from 'wagmi/connectors/metaMask'

const { chains, publicClient, webSocketPublicClient } = configureChains(
  [mainnet],
  [publicProvider()]
)

const config = createConfig({
  autoConnect: true,
  connectors: [new MetaMaskConnector({ chains })],
  publicClient,
  webSocketPublicClient,
})

function App() {
  return (
    <WagmiConfig config={config}>
      {/* Your app components */}
    </WagmiConfig>
  )
}
```
Questa configurazione inizializza Wagmi per interagire con la mainnet Ethereum usando MetaMask come connettore principale.

## Variabili in lettura

```solidity
uint256 public currentPrice;
// currentPrice
// prezzo di una shard in GPB*100

uint256 public constant MAX_SUPPLY = 25000;
uint256 public constant MAX_MINT_PER_TX = 5;
uint256 public totalMinted = 0;
```
### currentPrice
prezzo di una shard in GPB*100

### MAX_SUPPLY
supply massima delle shard

### MAX_MINT_PER_TX
massimo ammontare di shrd acquistabili in una transazione

### totalMinted
totale shard mintate

## Funzioni di lettura

### totalSupply e remainingSupply

Questo componente mostra il numero totale di Shard NFT emessi e quanti possono ancora essere mintati.
La funzione totalSupply del contratto viene chiamata usando l'hook useContractRead di Wagmi. Il risultato viene visualizzato direttamente nell'interfaccia utente, mostrando il numero totale di Shard NFT in circolazione.
Simile a totalSupply, remainingSupply utilizza useContractRead per ottenere il numero rimanente di Shard NFT che possono essere mintati. Questo aiuta gli utenti a capire la scarsità attuale del token.

```javascript
function SupplyInfo() {
  const { data: totalSupply } = useContractRead({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'totalSupply',
  })

  const { data: remainingSupply } = useContractRead({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'remainingSupply',
  })

  return (
    <div>
      <p>Total Supply: {totalSupply?.toString()}</p>
      <p>Remaining Supply: {remainingSupply?.toString()}</p>
    </div>
  )
}
```

### getEthPrice

Questo componente permette agli utenti di inserire un importo in GBP * 100 e vedere il corrispondente prezzo in ETH. Utilizza useContractRead con l'importo in pence come argomento per chiamare la funzione getEthPrice del contratto.

```javascript
function PriceInfo() {
  const [penceAmount, setPenceAmount] = useState('1000')
  const { data: ethPrice } = useContractRead({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'getEthPrice',
    args: [penceAmount],
  })

  return (
    <div>
      <input 
        type="number" 
        value={penceAmount} 
        onChange={(e) => setPenceAmount(e.target.value)}
      />
      <p>Price in ETH: {ethPrice ? ethers.utils.formatEther(ethPrice) : 'N/A'}</p>
    </div>
  )
}
```

### balanceOf

Questo componente utilizza useAccount per ottenere l'indirizzo del wallet connesso e poi useContractRead per chiamare balanceOf. Mostra il saldo di Shard NFT dell'utente corrente.

```javascript
 UserBalance() {
  const { address } = useAccount()
  const { data: balance } = useContractRead({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'balanceOf',
    args: [address, 0],
  })

  return <p>Your Shard balance: {balance?.toString()}</p>
}
```

## Funzioni di scrittura

### mintShard

Questo componente gestisce il processo di minting. Utilizza usePrepareContractWrite per preparare la transazione, useContractWrite per eseguirla, e useWaitForTransaction per monitorarne lo stato. L'utente può specificare la quantità di Shard da mintare. La funzione è payable quindi prma bisogna chiamare prin

```javascript
MintShard() {
  const [amount, setAmount] = useState('1')

  const { config } = usePrepareContractWrite({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'mintShard',
    args: [amount],
    overrides: {
      value: ethPrice, // Calcolato in base all'amount
    },
  })

  const { data, write } = useContractWrite(config)

  const { isLoading, isSuccess } = useWaitForTransaction({
    hash: data?.hash,
  })

  return (
    <div>
      <input 
        type="number" 
        value={amount} 
        onChange={(e) => setAmount(e.target.value)}
      />
      <button onClick={() => write?.()}>Mint Shard</button>
      {isLoading && <p>Transaction pending...</p>}
      {isSuccess && <p>Transaction confirmed!</p>}
    </div>
  )
}
```

## Funzioni amministrative

### setPrice

```javascript
function SetPrice() {
  const [newPrice, setNewPrice] = useState('')

  const { config } = usePrepareContractWrite({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'setPrice',
    args: [newPrice],
  })
  const { write } = useContractWrite(config)

  return (
    <div>
      <input 
        type="number" 
        value={newPrice} 
        onChange={(e) => setNewPrice(e.target.value)}
      />
      <button onClick={() => write?.()}>Set New Price</button>
    </div>
  )
}
```
Questo componente permette al proprietario del contratto di impostare un nuovo prezzo per il minting.

### withdraw

```javascript
function WithdrawFunds() {
  const { config } = usePrepareContractWrite({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'withdraw',
  })
  const { write } = useContractWrite(config)

  return <button onClick={() => write?.()}>Withdraw Funds</button>
}
```
Questo componente permette al proprietario del contratto di prelevare i fondi accumulati.
