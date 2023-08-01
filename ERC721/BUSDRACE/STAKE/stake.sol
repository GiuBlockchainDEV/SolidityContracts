// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./interface.sol";

contract NFTStaking is ERC721A__IERC721Receiver {

    // L'elenco dei contratti consentiti.
    address[] public allowedContracts;

    mapping (address => mapping (address => uint256[])) public _ownedTokens;
    mapping (address => mapping (address => mapping (uint256 => uint256))) public _tokenValues;

    function addAllowedContract(address contractAddress) public {
    // Aggiungi il contratto all'elenco dei contratti consentiti.
    allowedContracts.push(contractAddress);}

    function removeAllowedContract(address contractAddress) public {
        // Rimuovi il contratto dall'elenco dei contratti consentiti.
        for (uint256 i = 0; i < allowedContracts.length; i++) {
            if (allowedContracts[i] == contractAddress) {
                allowedContracts[i] = allowedContracts[allowedContracts.length - 1];
                allowedContracts.pop();
                break;}}}

    function getPurchaseFromTokenId(IContract _contractAddress, uint256 _tokenId) public view returns (address, uint256) {
        return _contractAddress.tokenId(_tokenId);}

    function stakeNFT(address nftAddress, uint256 tokenId) public {
        // Controlla se il contratto è consentito.
        bool isAllowed = false;
        for (uint256 i = 0; i < allowedContracts.length; i++) {
            if (allowedContracts[i] == nftAddress) {
                isAllowed = true;
                break;}}
        require(isAllowed, "Contratto NFT non consentito");

        IERC721A nftToken = IERC721A(nftAddress);
        IContract contractToken = IContract(nftAddress);
        (, uint256 amountPaid) = getPurchaseFromTokenId(contractToken, tokenId);
        // Transfer the NFT from the staker to this contract
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
        addToken(nftAddress, tokenId, amountPaid);}

    function unstakeNFT(address nftAddress, uint256 tokenId) public {
        // Controlla se il token è in stake
        bool isInStake = false;
        for (uint256 i = 0; i < _ownedTokens[msg.sender][nftAddress].length; i++) {
            if (_ownedTokens[msg.sender][nftAddress][i] == tokenId) {
                isInStake = true;
                break;}}
        require(isInStake, "Token non in stake");

        IERC721A nftToken = IERC721A(nftAddress);
        // Trasferisci l'NFT dal contratto allo staker
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
        removeToken(nftAddress, tokenId);}

    function unstakeAllNFTs(address contractAddress) public {
        // Ottieni l'elenco dei tokenIds per l'indirizzo del wallet e l'indirizzo del contratto specificato.
        uint256[] memory tokenIds = _ownedTokens[msg.sender][contractAddress];
        // Crea un'istanza del contratto NFT.
        IERC721A nftToken = IERC721A(contractAddress);
        // Itera su tutti i tokenIds e ritira ciascuno di essi.
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Trasferisci l'NFT dal contratto allo staker.
            nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
            // Rimuovi il token.
            removeToken(contractAddress, tokenId);}
        // Dopo aver ritirato tutti gli NFT, cancella l'elenco dei tokenIds.
        delete _ownedTokens[msg.sender][contractAddress];}


    function addToken(address contractAddress, uint256 tokenId, uint256 value) public {
        _tokenValues[msg.sender][contractAddress][tokenId] = value;
        _ownedTokens[msg.sender][contractAddress].push(tokenId);}

    function removeToken(address contractAddress, uint256 tokenId) public {
        delete _tokenValues[msg.sender][contractAddress][tokenId];

        uint256[] storage ownedTokens = _ownedTokens[msg.sender][contractAddress];
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            if (ownedTokens[i] == tokenId) {
                ownedTokens[i] = ownedTokens[ownedTokens.length - 1];
                ownedTokens.pop();
                break;}}}

    function getTokenValue(address wallet, address contractAddress, uint256 tokenId) public view returns (uint256) {
        return _tokenValues[wallet][contractAddress][tokenId];}

    function getTotalValue(address wallet, address contractAddress) public view returns (uint256) {
        uint256 totalValue = 0;

        // Ottieni l'elenco dei tokenId per il wallet e il contratto specificati.
        uint256[] memory tokenIds = _ownedTokens[wallet][contractAddress];

        // Itera su tutti i tokenId e somma i loro valori.
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalValue += _tokenValues[wallet][contractAddress][tokenIds[i]];}

        return totalValue;}

    function getOwnedTokens(address wallet, address contractAddress) public view returns (uint256[] memory) {
        return _ownedTokens[wallet][contractAddress];}

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
            return ERC721A__IERC721Receiver.onERC721Received.selector;}}
