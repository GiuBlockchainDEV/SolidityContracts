// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./contract.sol";
import "./library.sol";

contract aureus is ERC721A, Ownable, ReentrancyGuard {

    IERC1155 public shardAddress;
    uint256 public constant aureusSupply = 5000;

     constructor() ERC721A("Aureus", "AURE") {
        _safeMint(address(this), aureusSupply);
     }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    uint256 public tokenSwapped;

    bool public paused = true;

    function pauseNFT (bool _paused) public onlyOwner {
        paused = _paused;
    }

    bool public revealed = false;
    string public hiddenMetadataURI = "ipfs://---/hidden.json";
    string public publicURI;

    function revealNFT (bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setHiddenMetadataURI(string memory _hiddenMetadataURI) public onlyOwner {
        hiddenMetadataURI = _hiddenMetadataURI;
    }

    function tokenURI (uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (revealed == false) {
            return hiddenMetadataURI;}

        return _baseURI();
    }

    function setPublicURI (string memory _publicURI) public onlyOwner {
        publicURI = _publicURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return publicURI;
    }

    uint256 public constant shardID = 0;

    function swapAureus (uint256 _amount) public nonReentrant {
        require(!paused, "Il contratto e in pausa");
        require((tokenSwapped + _amount) <= aureusSupply, "Aureus terminati");
        uint256 shardAmount = _amount * 5;
        uint256 balance = shardAddress.balanceOf(msg.sender, shardID);
        require(balance >= shardAmount, "Non hai abbastanza shard");
        shardAddress.safeTransferFrom(msg.sender, address(0), shardID, shardAmount, '');

        for (uint256 i = 0; i < _amount; i++) {
            tokenSwapped++;
            safeTransferFrom(address(this), msg.sender, tokenSwapped);
        }
    }

}
