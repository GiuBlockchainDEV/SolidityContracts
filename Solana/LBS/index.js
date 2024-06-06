const {
    createMint,
    getOrCreateAssociatedTokenAccount,
    getAccount,
    setAuthority,
    AuthorityType,
    mintTo,
    burn,
    transfer
} = require('@solana/spl-token');
const {
    Connection,
    clusterApiUrl,
    Keypair,
    LAMPORTS_PER_SOL,
    PublicKey
} = require('@solana/web3.js');
const base58 = require('bs58');

require('dotenv').config();

const connection = new Connection(clusterApiUrl("devnet"), 'confirmed');

const privatekey = base58.decode(process.env.PRIVATE_KEY);
const wallet = Keypair.fromSecretKey(privatekey);

async function fundWallet() {
    const signature = await connection.requestAirdrop(wallet.publicKey, LAMPORTS_PER_SOL);
    await connection.confirmTransaction(signature);
}

async function getAccountBalance(accountAddress) {
    const tokenAccountInfo = await getAccount(connection, accountAddress);
    return tokenAccountInfo.amount;
}

async function transferTokens(recipient, token, fromTokenAccount, amount) {
    const toPublicKey = new PublicKey(recipient);
    const toTokenAccount = await getOrCreateAssociatedTokenAccount(connection, wallet, token, toPublicKey);
    const signature = await transfer(
        connection,         // Connection to Solana                
        wallet,             // Fee payer
        fromTokenAccount.address,   // Sender
        toTokenAccount.address,     // Receiver
        wallet.publicKey,           // Wallet signer
        amount               // Amount
    );

    await connection.confirmTransaction(signature);
    return signature;
}

async function disableMint(token) {
    await setAuthority(
        connection, // Connection to Solana
        wallet, // Fee payer 
        token, // the token
        wallet.publicKey, // the current authority
        AuthorityType.MintTokens, // the type of Authority to set
        null // This sets the mint authority to null so nobody can mint
    )
}

async function burnTokens(tokenAccount, token, amount) {
    await burn(
        connection,
        wallet,
        tokenAccount,
        token,
        wallet.publicKey,
        amount
    )
}

async function createToken() {
    const balance = await connection.getBalance(wallet.publicKey);

    if (balance < LAMPORTS_PER_SOL) {
        await fundWallet();
    }

    const token = await createMint(
        connection,         // Connection to Solana
        wallet,             // Fee payer
        wallet.publicKey,   // Mint authority
        wallet.publicKey,   // Freeze authority
        9                   // Number of decimals
    );

    const tokenAddress = token.toString();

    console.log(`The token was created, here is the address: ${tokenAddress}`);

    const tokenAccount = await getOrCreateAssociatedTokenAccount(connection, wallet, token, wallet.publicKey);
    const accountAddress = tokenAccount.address.toString();
    console.log(`Created an account for the owner of the token, here is the address: ${accountAddress}`);

    const initialBalance = await getAccountBalance(tokenAccount.address);
    console.log(`Initially, the account has ${initialBalance} tokens`);

    await mintTo(
        connection,         // Connection to Solana
        wallet,             // Fee payer
        token,              // Token to mint
        tokenAccount.address,       // Receiver of the tokens
        wallet.publicKey,           // Mint authority
        10000 * Math.pow(10, 9)     // Amount of tokens
    );

    let balanceAfterMint = await getAccountBalance(tokenAccount.address);
    console.log(`After minting, the account has ${balanceAfterMint} tokens`);

    await disableMint(token);
    console.log(`Mint Disabled`);

    try {
        await mintTo(
            connection,         // Connection to Solana
            wallet,             // Fee payer
            token,              // Token to mint
            tokenAccount.address,       // Receiver of the tokens
            wallet.publicKey,           // Mint authority
            10000 * Math.pow(10, 9)     // Amount of tokens
        );
    } catch (error) {
        console.log("Minting failed as expected because minting is disabled.");
    }



    
    const transferSignature = await transferTokens(
        "2tueQsrouWCFawivcCeVWsDHvzSiqLGwwbyGbwBcr8qj",
        token, tokenAccount,
        10000 * Math.pow(10, 9)
    );

    console.log(`Transferred 10000 tokens with signature ${transferSignature}`);

    /*
    console.log(`Burning tokens - Token Account Address: ${tokenAccount.address}, Token: ${token}`);
    await burnTokens(tokenAccount.address, token, 10 * Math.pow(10, 9));
    console.log(`Just burned 10 tokens`);

    const balanceAfterBurn = await getAccountBalance(tokenAccount.address);
    console.log(`After burning, the account has ${balanceAfterBurn} tokens`);

    await mintTo(
        connection,         // Connection to Solana
        wallet,             // Fee payer
        token,              // Token to mint
        tokenAccount.address,       // Receiver of the tokens
        wallet.publicKey,           // Mint authority
        10000 * Math.pow(10, 9)     // Amount of tokens
    );

    balanceAfterMint = await getAccountBalance(tokenAccount.address);
    console.log(`After minting, the account has ${balanceAfterMint} tokens`);

    await disableMint(token);
    console.log(`Mint Disabled`);

    try {
        await mintTo(
            connection,         // Connection to Solana
            wallet,             // Fee payer
            token,              // Token to mint
            tokenAccount.address,       // Receiver of the tokens
            wallet.publicKey,           // Mint authority
            10000 * Math.pow(10, 9)     // Amount of tokens
        );
    } catch (error) {
        console.log("Minting failed as expected because minting is disabled.");
    }

    balanceAfterMint = await getAccountBalance(tokenAccount.address);
    console.log(`After minting attempt, the account has ${balanceAfterMint} tokens`);

    */
}

createToken()
    .then(() => {
        console.log(`Done!`);
    })
    .catch((error) => {
        console.log(`error ${error}`);
    });
