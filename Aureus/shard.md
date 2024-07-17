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
```
Questa configurazione inizializza Wagmi per interagire con la mainnet Ethereum usando MetaMask come connettore principale.

## Funzioni di lettura

### totalSupply e remainingSupply

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
Questo componente mostra il numero totale di Shard NFT emessi e quanti possono ancora essere mintati.

### getEthPrice

```
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
Questo componente permette agli utenti di calcolare il prezzo in ETH per un dato importo in pence.

### balanceOf

```
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
Questo componente mostra il saldo di Shard NFT dell'utente corrente.

## Funzioni di scrittura

### mintShard

```
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
Questo componente permette agli utenti di mintare nuovi Shard NFT.

## Funzioni amministrative

### setPrice

```
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

```
WithdrawFunds() {
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
