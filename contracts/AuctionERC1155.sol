// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract MyERC1155 is ERC1155, ERC1155URIStorage{
    struct Auction {
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 startingPrice;
        uint256 unlimitedAuctionStartTime;
    }

    address private _admin;
    uint256 private _tokenIdCounter;
    mapping (string => bool) private _uris;
    mapping (uint256 => address) private _creator;
    mapping (uint256 => Auction[]) public unlimitedAuctions;

    constructor() ERC1155("") {
        _admin = msg.sender;
    }

    function mint(uint256 _amount, string memory _tokenURI) public {
        require(_amount > 0, "Amount must be grater than zero");
        require(bytes(_tokenURI).length > 0, "TokenURI can not be empty");
        require(!_uris[_tokenURI], "URI already exists");
        _tokenIdCounter++;
        uint256 id = _tokenIdCounter;
        _mint(msg.sender, id, _amount, "");
        _setURI(id, _tokenURI);
        _uris[_tokenURI] = true;
        _creator[id] = msg.sender;
    }

    function mintToExisiting(uint256 _tokenId, uint256 _amount) public{
       require(msg.sender == _creator[_tokenId], "You are not the orginal creator of this token");
        require(_amount > 0, "Amount must be gerater than zero");
        _mint(msg.sender, _tokenId, _amount, "");
    } 

    function uri(uint256 tokenId) public view override(ERC1155URIStorage, ERC1155) returns (string memory) {
        return super.uri(tokenId);
    }

    function startUnlimitedAuction(uint256 _tokenId, uint256 _amount, uint256 _startingPrice) public {
        require(_amount > 0 && _startingPrice > 0, "Amount and starting price must be greate than zero");
        require(balanceOf(msg.sender, _tokenId) >= _amount, "Insufficent balance");
        unlimitedAuctions[_tokenId].push(Auction(msg.sender, _tokenId, _amount, _startingPrice, block.timestamp));
    }

    function getUnlimitedAuction(uint256 _tokenId) public view returns(Auction[] memory) {
        return unlimitedAuctions[_tokenId];
    }
}