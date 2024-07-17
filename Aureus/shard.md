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
//Prezzo di una shard in GPB*100
uint256 public currentPrice;

//Supply massima delle shard
uint256 public constant MAX_SUPPLY = 25000;

//Massimo ammontare di shrd acquistabili in una transazione
uint256 public constant MAX_MINT_PER_TX = 5;

//Totale shard mintate
uint256 public totalMinted = 0;
```
## Funzioni di lettura
### totalSupply e remainingSupply
```solidity
//Questo componente mostra il numero totale di Shard NFT emessi
function totalSupply() public view returns (uint256) {
        return totalMinted;
    }


//Questo componente mostra il numero totale di Shard NFT rimamenti da mintare
function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalMinted;
    }
```
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
```solidity
//Questo componente mostra il valore in GBP*100 in wei di ETH
unction getEthPrice(uint256 penceAmount) public view returns (uint256) {
        (, int256 ethUsdPrice,,,) = ethUsdPriceFeed.latestRoundData();
        (, int256 gbpUsdPrice,,,) = gbpUsdPriceFeed.latestRoundData();
        require(ethUsdPrice > 0 && gbpUsdPrice > 0, "Invalid price");
        
        uint256 ethPerUsd = uint256(ethUsdPrice); // 8 decimals
        uint256 gbpPerUsd = uint256(gbpUsdPrice); // 8 decimals
        
        uint256 numerator = penceAmount * 1e18;
        numerator = numerator * gbpPerUsd;
        uint256 denominator = ethPerUsd * 100;
        
        return numerator / denominator;
    }
```
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
```solidity
//Questo funzione payable permette di mintare fino a 5 shard a transazione
function mintShard(uint256 amount) external payable nonReentrant whenNotPaused {
        require(amount > 0 && amount <= MAX_MINT_PER_TX, "Invalid amount");
        require(totalMinted + amount <= MAX_SUPPLY, "Exceeds max supply");

        uint256 priceInEth = getEthPrice(currentPrice * amount);
        require(msg.value >= priceInEth, "Insufficient payment");
        
        _mint(msg.sender, 0, amount, "");
        totalMinted += amount;
        
        // Refund excess payment
        if(msg.value > priceInEth) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - priceInEth}("");
            require(success, "Refund failed");
        }

        emit ShardsMinted(msg.sender, amount);
    }
```
Questo componente gestisce il processo di minting. Utilizza usePrepareContractWrite per preparare la transazione, useContractWrite per eseguirla, e useWaitForTransaction per monitorarne lo stato. L'utente può specificare la quantità di Shard da mintare. La funzione è payable quindi prma bisogna chiamare **currentPrice** e poi passrlo per la funzione **getEthPrice**
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
```solidity
//Questo funzione payable permette di fissare il prezzo in GBP*100
function setPrice(uint256 newPriceInPence) external onlyOwner {
        require(newPriceInPence > 0, "Price must be greater than zero");
        currentPrice = newPriceInPence;
        emit PriceUpdated(newPriceInPence);
    }
```
Questo componente permette al proprietario del contratto di impostare un nuovo prezzo per il minting.
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
### withdraw e recoverERC20
```solidity
//Questo funzione permette di ritirare i fondi ETH dal contratto, è chiamabile solo dall'owner
function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
```
```solidity
//Questo funzione permette di ritirare i fondi ERC20 dl contratto, è chiamabile solo dall'owner
function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit ERC20Recovered(tokenAddress, tokenAmount);
    }
```
Questo funzioni permettono al proprietario del contratto di prelevare i fondi accumulati.
