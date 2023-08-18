// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract TotemAnimalContract is ERC721, Ownable, ERC721Enumerable {
    uint256 public constant MAX_PER_MINT = 1;
    uint256 mintPrice = 0;
    string[] public colors = ['FCD22D', '735DFF', '54DCE7', 'FF7DCB', '0052FF'];
    string[] public adjectives = ['Majestic', 'Playful', 'Mysterious', 'Graceful', 'Fierce', 'Elegant', 'Quirky', 'Vibrant', 'Swift', 'Enigmatic'];
    string[] public animals = [unicode"Unicorn 🦄",
                               unicode"Duck 🦆",
                               unicode"Monkey 🐒",
                               unicode"Frog 🐸",
                               unicode"Fox 🦊",
                               unicode"Panda 🐼",
                               unicode"Mouse 🐭",
                               unicode"Owl 🦉",
                               unicode"Wolf 🐺",
                               unicode"Cat 🐱",
                               unicode"Dog 🐶",
                               unicode"Whale 🐳",
                               unicode"Parrot 🦜",
                               unicode"Flamingo 🦩",
                               unicode"Turtle 🐢"];
    string[] public chain = ['Ethereum', 'zkSync Era', 'Base', 'Polygon zkEVM', 'Optimism', 'Arbitrum', 'Avalanche', 'Polygon', 'Bitcoin', 'Zora', 'Gnosis'];
    

    uint256 public endMint = 1693526400; //Fri Sep 01 2023 00:00:00 GMT+0000
    mapping (uint256 => address) public minter;
    // mapping (uint256 => TotemAnimal) public tokenDesc;
    mapping (address => bool) public minted;

    constructor() ERC721("Base Onchain Totem Animal", "BOTA") {}

    function mint() external payable {
        require(block.timestamp < endMint, "Minting time is complete");
        require(msg.value >= mintPrice, "Insufficient payment");
        require(minted[msg.sender] == false, "Already minted");


        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
        minter[tokenId] = msg.sender;
        minted[msg.sender] = true;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId);
        return _tokenURI(tokenId);
    }

    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        uint256 wallet = uint256(uint160(minter[tokenId]));
        uint256 walletOwner = uint256(uint160(ownerOf(tokenId)));
        string memory image = _getSVG(tokenId, wallet, walletOwner);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name":"', unicode"🔵", ' Based Onchain Totem Animal #', Strings.toString(tokenId), '",',
                    '"description":"100% on-chain generative.",',
                    '"attributes":[',
                    '{"trait_type":"Minter","value":"', Strings.toHexString(wallet), '"},',
                    '{"trait_type":"Owner","value":"', Strings.toHexString(walletOwner), '"}'
                '],',
                    '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _getSVG(uint256 tokenId, uint256 wallet, uint256 walletOwner) private view returns (string memory) {
        string memory image = string(abi.encodePacked(
            '<svg viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            '<rect width="100%" height="100%" fill="#FFFFFF"/>',
            '<style> .small {font: italic 30px sans-serif;} .heavy {font: bold 50px sans-serif;} .medium {font: 40px sans-serif;} </style>',
            _getAnimal(tokenId, wallet),
            '<text x="5.5%" y="97%" font-family="monospace" font-size="9">Totem Animal creator: ',
            Strings.toHexString(walletOwner),
            '</text></svg>'
        ));
        return image;
    }

    function _getAnimal(uint256 _tokenId, uint256 _wallet) private view returns (string memory){
        string memory data;
        string[] memory colorsTmp = _shuffleColors(_tokenId, _wallet);
        string memory randomAnimal = _getRandom(_tokenId, _wallet, animals);
        string memory randomAdj = _getRandom(_tokenId, _wallet, adjectives);
        string memory randomChain = _getRandom(_tokenId, _wallet, chain);

        data = string(abi.encodePacked(data, '<text class="small" x="50" y="200" fill="#', colorsTmp[4],'">', randomAdj, '</text>'));
        data = string(abi.encodePacked(data, '<text class="medium" x="50" y="245" fill="#', colorsTmp[3],'">', randomChain, '</text>'));
        data = string(abi.encodePacked(data, '<text class="heavy" x="50" y="300" fill="#', colorsTmp[2],'">', randomAnimal, '</text>'));
        data = string(abi.encodePacked(data, '<circle cx="50" cy="50" r="15" stroke="#FFFFFF" fill="#', colorsTmp[0], '">',
                                             '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 50 50" to="360 75 75" dur="2s" repeatCount="indefinite"/>',
                                             '</circle>'));
        return data;
    }

    function _getRandom(uint _tokenId, uint _wallet, string[] memory _arr) private pure returns (string memory) {
        uint ind = uint256(keccak256(abi.encodePacked(_tokenId, _wallet))) % (_arr.length);
        return _arr[ind];
    } 

    function _shuffleColors(uint256 tokenId, uint256 wallet) private view returns (string[] memory) {
        string[] memory colorsTmp = colors;
        for (uint256 i = 0; i < colorsTmp.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(tokenId, wallet))) % (colorsTmp.length - i);
            string memory temp = colorsTmp[n];
            colorsTmp[n] = colorsTmp[i];
            colorsTmp[i] = temp;
        }
        return colorsTmp;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setEndMint(uint256 newEndMint) external onlyOwner {
        endMint = newEndMint;
    }


    function withdrawAmount(uint256 amount, address to) external payable onlyOwner {
        require(payable(to).send(amount));
    }

    function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "Withdraw failed");
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}
