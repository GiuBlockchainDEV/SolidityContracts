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
