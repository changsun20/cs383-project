// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract ArtDAO {
    uint256 public constant MINT_INTERVAL = 7 days;
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public lastMintTime;
    uint256 public nextTokenId;
    
    struct Auction {
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool settled;
    }
    
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => Auction) public auctions;
    
    event Minted(uint256 tokenId, address to);
    event AuctionStarted(uint256 tokenId, uint256 startTime, uint256 endTime);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event AuctionSettled(uint256 tokenId, address winner, uint256 amount);
    
    constructor() {
        lastMintTime = block.timestamp;
        nextTokenId = 1;
    }
    
    function mint() external {
        require(block.timestamp >= lastMintTime + MINT_INTERVAL, "Mint interval not reached");
        
        uint256 tokenId = nextTokenId;
        tokenOwner[tokenId] = address(this);
        nextTokenId++;
        
        lastMintTime = block.timestamp;
        
        emit Minted(tokenId, address(this));
        
        startAuction(tokenId);
    }
    
    function startAuction(uint256 tokenId) internal {
        require(tokenOwner[tokenId] == address(this), "Token not owned by contract");
        
        Auction storage auction = auctions[tokenId];
        auction.tokenId = tokenId;
        auction.startTime = block.timestamp;
        auction.endTime = block.timestamp + AUCTION_DURATION;
        auction.highestBid = 0;
        auction.highestBidder = address(0);
        auction.settled = false;
        
        emit AuctionStarted(tokenId, auction.startTime, auction.endTime);
    }
    
    function bid(uint256 tokenId) external payable {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp >= auction.startTime, "Auction not started");
        require(block.timestamp <= auction.endTime, "Auction ended");
        require(!auction.settled, "Auction already settled");
        require(msg.value > auction.highestBid, "Bid too low");
        
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }
    
    function settleAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp > auction.endTime, "Auction still ongoing");
        require(!auction.settled, "Auction already settled");
        
        auction.settled = true;
        
        if (auction.highestBidder != address(0)) {
            tokenOwner[tokenId] = auction.highestBidder;
            emit AuctionSettled(tokenId, auction.highestBidder, auction.highestBid);
        } else {
            tokenOwner[tokenId] = address(this);
            emit AuctionSettled(tokenId, address(0), 0);
        }
    }
    
    function balanceOf(address owner) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (tokenOwner[i] == owner) {
                count++;
            }
        }
        return count;
    }
    
    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenOwner[tokenId];
    }
    
    function transfer(address to, uint256 tokenId) external {
        require(tokenOwner[tokenId] == msg.sender, "Not owner");
        tokenOwner[tokenId] = to;
    }
    
    function treasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {}
}