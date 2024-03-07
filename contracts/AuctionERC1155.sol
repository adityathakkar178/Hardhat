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

    struct Bid {
        address bidder;
        uint256 biddingPrice;
    }

    address private _admin;
    uint256 private _tokenIdCounter;
    mapping (string => bool) private _uris;
    mapping (uint256 => address) private _creator;
    mapping (uint256 => Auction[]) public unlimitedAuctions;
    mapping (uint256 => mapping(uint256 => Bid[])) public bidders; 

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

    function placeBid(uint256 _tokenId, uint256 _seller) public payable {
        require(unlimitedAuctions[_tokenId].length > 0, "Invalid auction");
        require(msg.sender != unlimitedAuctions[_tokenId][_seller].seller, "Seller can not place bid");
        require(msg.value > unlimitedAuctions[_tokenId][_seller].startingPrice, "Bidding price must be greater than starting price");
        bidders[_tokenId][_seller].push(Bid(msg.sender, msg.value));
    }

    function getBidders(uint256 _tokenId, uint256 _bidder) public view returns(Bid[] memory) {
        return bidders[_tokenId][_bidder];
    }

    function acceptBid(uint256 _tokenId, uint256 _auction, uint256 _bidder) public {
        Auction memory selectedAuction = unlimitedAuctions[_tokenId][_auction];
        Bid memory selectedBid =  bidders[_tokenId][_auction][_bidder];
        require(msg.sender == selectedAuction.seller, "only seller can accept a bid");
        _safeTransferFrom(selectedAuction.seller, selectedBid.bidder, _tokenId, selectedAuction.amount, "");
        payable(selectedAuction.seller).transfer(selectedBid.biddingPrice);
        delete unlimitedAuctions[_tokenId][_auction];
        delete bidders[_tokenId][_auction];
    }
}