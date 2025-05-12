// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenomicsLuneNFT {

    string public name = "TokenomicsLuneNFT";
    string public symbol = "TLN";
    uint256 public upgradeFee = 0.1 ether;  // Fee to upgrade NFT (can be adjusted)

    // Mapping for storing ownership of NFTs
    mapping(uint256 => address) public ownerOfToken;
    mapping(address => uint256[]) public userTokens; // To track user's NFTs for upgrading
    mapping(uint256 => string) public tokenMetadata;  // Storing metadata (e.g., token attributes)

    uint256 private _tokenIdCounter = 0;

    // Events
    event Mint(address indexed to, uint256 tokenId);
    event Burn(address indexed owner, uint256 tokenId);
    event Upgrade(address indexed owner, uint256[] burnedTokenIds, uint256 newTokenId);

    // Modifier to check if the sender is the owner of the token
    modifier onlyOwner(uint256 tokenId) {
        require(ownerOfToken[tokenId] == msg.sender, "You must own the NFT to interact with it");
        _;
    }

    // Function to mint new NFTs
    function mintNFT(address to, string memory metadata) public payable returns (uint256) {
        require(msg.value >= upgradeFee, "Insufficient fee to mint NFT");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        ownerOfToken[tokenId] = to;
        tokenMetadata[tokenId] = metadata;

        userTokens[to].push(tokenId);

        emit Mint(to, tokenId);
        return tokenId;
    }

    // Function to burn NFT (called during upgrade)
    function burnNFT(uint256 tokenId) public onlyOwner(tokenId) {
        address owner = ownerOfToken[tokenId];

        // Remove token from owner's list
        uint256[] storage tokens = userTokens[owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }

        // Remove NFT ownership
        delete ownerOfToken[tokenId];
        delete tokenMetadata[tokenId];

        emit Burn(owner, tokenId);
    }

    // Function to upgrade NFT by burning existing ones and minting a new one
    function upgradeNFT(uint256[] memory tokenIds) public payable {
        require(msg.value >= upgradeFee, "Insufficient fee to upgrade NFTs");

        // Burn all the NFTs provided for the upgrade
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burnNFT(tokenIds[i]);
        }

        // Mint a new NFT as the upgraded version
        string memory newMetadata = "Upgraded Version"; // You can modify the metadata logic here
        uint256 newTokenId = mintNFT(msg.sender, newMetadata);

        emit Upgrade(msg.sender, tokenIds, newTokenId);
    }

    // Function to allow the contract owner to withdraw collected fees
    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Get all tokens owned by an address
    function getOwnedTokens(address owner) public view returns (uint256[] memory) {
        return userTokens[owner];
    }

    // Function to get the metadata of a token
    function getTokenMetadata(uint256 tokenId) public view returns (string memory) {
        return tokenMetadata[tokenId];
    }
}
