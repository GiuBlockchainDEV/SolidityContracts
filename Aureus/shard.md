# ShardNFT Frontend Interface

Questa è un'implementazione frontend per il contratto ShardNFT utilizzando React e Wagmi per l'interazione con la blockchain Ethereum.

## Sommario

- [Configurazione iniziale](#configurazione-iniziale)
- [Funzioni di lettura](#funzioni-di-lettura)
- [Funzioni di scrittura](#funzioni-di-scrittura)
- [Funzioni amministrative](#funzioni-amministrative)
- [Gestione degli eventi](#gestione-degli-eventi)
- [Note aggiuntive](#note-aggiuntive)

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

## Questa configurazione inizializza Wagmi per interagire con la mainnet Ethereum usando MetaMask come connettore principale.

### Funzioni di lettura

#### totalSupply e remainingSupply

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
Questo componente mostra il numero totale di Shard NFT emessi e quanti possono ancora essere mintati.
getEthPrice
javascriptCopyfunction PriceInfo() {
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
Questo componente permette agli utenti di calcolare il prezzo in ETH per un dato importo in pence.
balanceOf
javascriptCopyfunction UserBalance() {
  const { address } = useAccount()
  const { data: balance } = useContractRead({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'balanceOf',
    args: [address, 0],
  })

  return <p>Your Shard balance: {balance?.toString()}</p>
}
Questo componente mostra il saldo di Shard NFT dell'utente corrente.
Funzioni di scrittura
mintShard
javascriptCopyfunction MintShard() {
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
Questo componente permette agli utenti di mintare nuovi Shard NFT.
Funzioni amministrative
setPrice
javascriptCopyfunction SetPrice() {
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
Questo componente permette al proprietario del contratto di impostare un nuovo prezzo per il minting.
withdraw
javascriptCopyfunction WithdrawFunds() {
  const { config } = usePrepareContractWrite({
    address: shardNFTAddress,
    abi: shardNFTABI,
    functionName: 'withdraw',
  })
  const { write } = useContractWrite(config)

  return <button onClick={() => write?.()}>Withdraw Funds</button>
}
Questo componente permette al proprietario del contratto di prelevare i fondi accumulati.
Altre funzioni amministrative
Implementazioni simili sono fornite per setURI, pause, unpause, e recoverERC20.
Gestione degli eventi
javascriptCopyfunction EventListener() {
  useContractEvent({
    address: shardNFTAddress,
    abi: shardNFTABI,
    eventName: 'ShardsMinted',
    listener(log) {
      console.log('ShardsMinted', log)
      // Aggiorna lo stato dell'app o mostra una notifica
    },
  })

  // Implementa listener simili per altri eventi (ShardsBurned, PriceUpdated, etc.)

  return null
}
Questo componente ascolta e reagisce agli eventi emessi dal contratto.
Note aggiuntive

Assicurati di gestire correttamente gli errori e di fornire feedback appropriato all'utente per tutte le interazioni con il contratto.
Implementa controlli per assicurarti che solo l'owner del contratto possa accedere alle funzioni amministrative.
Considera l'implementazione di un sistema di caching per ridurre il numero di chiamate alla blockchain.
Testa accuratamente tutte le funzionalità in un ambiente di test prima di deployare in produzione.

Questa implementazione frontend fornisce un'interfaccia completa per interagire con tutte le funzioni principali del contratto ShardNFT, utilizzando Wagmi per semplificare le interazioni con la blockchain Ethereum e React per creare un'interfaccia utente reattiva e user-friendly.
