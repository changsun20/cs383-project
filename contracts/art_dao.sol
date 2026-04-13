// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

/**
 * @title Interface for the ArtCommission contract
 * @dev The DAO uses this interface to read dispute participants and resolve the case.
 */
interface IArtCommission {
    function artist() external view returns (address);
    function buyer() external view returns (address);

    function artistWins() external;
    function buyerWins() external;
    function neitherWins() external;
}

/**
 * @title ArtDAO
 * @dev This contract:
 * 1. Maintains DAO NFT ownership
 * 2. Runs NFT auctions
 * 3. Selects jurors for disputes using weighted lottery
 * 4. Accepts juror votes
 * 5. Resolves disputes by calling the corresponding commission contract
 *
 * Important:
 * The random selection here is good enough for a school project prototype,
 * but not secure enough for production. In production, use Chainlink VRF or
 * another secure randomness source.
 */
contract ArtDAO {
    // =========================================================
    //                         CONSTANTS
    // =========================================================

    uint256 public constant MINT_INTERVAL = 7 days;
    uint256 public constant AUCTION_DURATION = 7 days;

    // =========================================================
    //                          STATE
    // =========================================================

    uint256 public lastMintTime;
    uint256 public nextTokenId;
    uint256 public nextDisputeId;

    /**
     * @dev Simple NFT ownership model.
     * This is not a full ERC721 implementation, but it matches your current DAO design.
     */
    mapping(uint256 => address) public tokenOwner;

    /**
     * @dev Tracks how many DAO NFTs each address owns.
     * Jury selection weight is based on this number.
     */
    mapping(address => uint256) public holderBalance;

    /**
     * @dev Keep a registry of addresses that have ever held a DAO NFT.
     * We keep them in the array even if they later sell all tokens.
     */
    mapping(address => bool) public holderExists;
    address[] public holders;

    /**
     * @dev Prevent multiple simultaneous active disputes for the same commission.
     */
    mapping(address => bool) public commissionHasActiveDispute;

    struct Auction {
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool settled;
    }

    mapping(uint256 => Auction) public auctions;

    /**
     * @dev Vote choices for dispute resolution.
     */
    enum VoteOption {
        None,
        Artist,
        Buyer,
        Neither
    }

    /**
     * @dev Stores all information about one DAO dispute.
     *
     * jurors:
     * - selected jurors for this dispute
     *
     * voteOf:
     * - each juror's selected vote
     *
     * hasVoted:
     * - whether that juror already voted
     */
    struct DisputeCase {
        address commission;
        bool panelSelected;
        bool resolved;
        uint256 panelSize;
        uint256 votingStart;
        uint256 votingEnd;

        address[] jurors;

        uint256 artistVotes;
        uint256 buyerVotes;
        uint256 neitherVotes;

        mapping(address => bool) hasVoted;
        mapping(address => VoteOption) voteOf;
    }

    mapping(uint256 => DisputeCase) private disputes;

    // =========================================================
    //                          EVENTS
    // =========================================================

    event Minted(uint256 tokenId, address to);
    event AuctionStarted(uint256 tokenId, uint256 startTime, uint256 endTime);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event AuctionSettled(uint256 tokenId, address winner, uint256 amount);

    event DisputeCreated(uint256 disputeId, address commission, uint256 panelSize);
    event JurorSelected(uint256 disputeId, address juror);
    event VoteCast(uint256 disputeId, address juror, VoteOption option);
    event DisputeResolved(uint256 disputeId, VoteOption outcome);

    // =========================================================
    //                        CONSTRUCTOR
    // =========================================================

    constructor() {
        lastMintTime = block.timestamp;
        nextTokenId = 1;
        nextDisputeId = 1;

        _addHolderIfNeeded(address(this));
    }

    // =========================================================
    //                     NFT / AUCTION LOGIC
    // =========================================================

    /**
     * @dev Mint a new DAO NFT into the DAO treasury and immediately start an auction.
     */
    function mint() external {
        require(block.timestamp >= lastMintTime + MINT_INTERVAL, "Mint interval not reached");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _moveToken(address(0), address(this), tokenId);

        lastMintTime = block.timestamp;

        emit Minted(tokenId, address(this));
        _startAuction(tokenId);
    }

    /**
     * @dev Internal helper to start an auction.
     */
    function _startAuction(uint256 tokenId) internal {
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

    /**
     * @dev Place a bid on an active auction.
     */
    function bid(uint256 tokenId) external payable {
        Auction storage auction = auctions[tokenId];

        require(block.timestamp >= auction.startTime, "Auction not started");
        require(block.timestamp <= auction.endTime, "Auction ended");
        require(!auction.settled, "Auction already settled");
        require(msg.value > auction.highestBid, "Bid too low");

        // Refund previous highest bidder.
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Settle an auction after it ends.
     */
    function settleAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];

        require(block.timestamp > auction.endTime, "Auction still ongoing");
        require(!auction.settled, "Auction already settled");

        auction.settled = true;

        if (auction.highestBidder != address(0)) {
            _moveToken(address(this), auction.highestBidder, tokenId);
            emit AuctionSettled(tokenId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionSettled(tokenId, address(0), 0);
        }
    }

    /**
     * @dev Transfer a DAO NFT from one owner to another.
     */
    function transfer(address to, uint256 tokenId) external {
        require(tokenOwner[tokenId] == msg.sender, "Not owner");
        require(to != address(0), "Invalid recipient");

        _moveToken(msg.sender, to, tokenId);
    }

    /**
     * @dev Return the number of DAO NFTs owned by an address.
     */
    function balanceOf(address owner) external view returns (uint256) {
        return holderBalance[owner];
    }

    /**
     * @dev Return the owner of a specific DAO NFT.
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenOwner[tokenId];
    }

    /**
     * @dev Return treasury ETH balance.
     */
    function treasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // =========================================================
    //                      DISPUTE CREATION
    // =========================================================

    /**
     * @dev Create a new dispute case.
     *
     * Usually this is called by an ArtCommission contract after it enters Disputed state.
     */
    function createDisputeCase(
        address commission,
        uint256 panelSize,
        uint256 votingDuration
    ) external returns (uint256 disputeId) {
        require(commission != address(0), "Invalid commission");
        require(panelSize > 0, "Panel size must be > 0");
        require(votingDuration > 0, "Voting duration must be > 0");
        require(!commissionHasActiveDispute[commission], "Commission already has active dispute");

        disputeId = nextDisputeId;
        nextDisputeId++;

        DisputeCase storage d = disputes[disputeId];
        d.commission = commission;
        d.panelSize = panelSize;
        d.panelSelected = false;
        d.resolved = false;
        d.votingStart = 0;
        d.votingEnd = 0;

        commissionHasActiveDispute[commission] = true;

        emit DisputeCreated(disputeId, commission, panelSize);
    }

    // =========================================================
    //                 JUROR SELECTION / VOTING
    // =========================================================

    /**
     * @dev Select jurors for a dispute using weighted lottery.
     *
     * Weight rule:
     * - A holder with more DAO NFTs has higher probability of being selected.
     *
     * Excluded addresses:
     * - the DAO treasury itself
     * - the artist in the commission
     * - the buyer in the commission
     *
     * Jurors are selected without duplication.
     */
    function selectJurors(uint256 disputeId, uint256 votingDuration) external {
        DisputeCase storage d = disputes[disputeId];

        require(d.commission != address(0), "Dispute does not exist");
        require(!d.panelSelected, "Panel already selected");
        require(!d.resolved, "Dispute already resolved");
        require(votingDuration > 0, "Voting duration must be > 0");

        address artistAddr = IArtCommission(d.commission).artist();
        address buyerAddr = IArtCommission(d.commission).buyer();

        (
            address[] memory candidates,
            uint256[] memory weights,
            uint256 candidateCount,
            uint256 totalWeight
        ) = _getEligibleCandidates(artistAddr, buyerAddr);

        require(candidateCount >= d.panelSize, "Not enough eligible holders");
        require(totalWeight > 0, "No eligible holders");

        bool[] memory picked = new bool[](candidateCount);

        for (uint256 i = 0; i < d.panelSize; i++) {
            // This is pseudo-randomness for demo / prototype use.
            uint256 rand = uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        disputeId,
                        i,
                        totalWeight
                    )
                )
            ) % totalWeight;

            uint256 runningWeight = 0;
            uint256 selectedIndex = type(uint256).max;

            for (uint256 j = 0; j < candidateCount; j++) {
                if (picked[j]) continue;

                runningWeight += weights[j];
                if (rand < runningWeight) {
                    selectedIndex = j;
                    break;
                }
            }

            require(selectedIndex != type(uint256).max, "Juror selection failed");

            picked[selectedIndex] = true;
            totalWeight -= weights[selectedIndex];

            d.jurors.push(candidates[selectedIndex]);

            emit JurorSelected(disputeId, candidates[selectedIndex]);
        }

        d.panelSelected = true;
        d.votingStart = block.timestamp;
        d.votingEnd = block.timestamp + votingDuration;
    }

    /**
     * @dev Selected jurors cast their vote.
     */
    function vote(uint256 disputeId, VoteOption option) external {
        DisputeCase storage d = disputes[disputeId];

        require(d.commission != address(0), "Dispute does not exist");
        require(d.panelSelected, "Panel not selected");
        require(!d.resolved, "Dispute already resolved");
        require(block.timestamp <= d.votingEnd, "Voting ended");
        require(option != VoteOption.None, "Invalid vote");
        require(_isJuror(disputeId, msg.sender), "Not selected juror");
        require(!d.hasVoted[msg.sender], "Already voted");

        d.hasVoted[msg.sender] = true;
        d.voteOf[msg.sender] = option;

        if (option == VoteOption.Artist) {
            d.artistVotes++;
        } else if (option == VoteOption.Buyer) {
            d.buyerVotes++;
        } else if (option == VoteOption.Neither) {
            d.neitherVotes++;
        }

        emit VoteCast(disputeId, msg.sender, option);
    }

    /**
     * @dev Resolve the dispute based on majority vote.
     *
     * Rule:
     * - strict highest vote wins
     * - ties default to Neither
     */
    function resolveDispute(uint256 disputeId) external {
        DisputeCase storage d = disputes[disputeId];

        require(d.commission != address(0), "Dispute does not exist");
        require(d.panelSelected, "Panel not selected");
        require(!d.resolved, "Already resolved");
        require(
            block.timestamp > d.votingEnd || _allJurorsVoted(disputeId),
            "Voting still active"
        );

        VoteOption outcome = _calculateOutcome(disputeId);

        d.resolved = true;
        commissionHasActiveDispute[d.commission] = false;

        if (outcome == VoteOption.Artist) {
            IArtCommission(d.commission).artistWins();
        } else if (outcome == VoteOption.Buyer) {
            IArtCommission(d.commission).buyerWins();
        } else {
            IArtCommission(d.commission).neitherWins();
        }

        emit DisputeResolved(disputeId, outcome);
    }

    // =========================================================
    //                        VIEW HELPERS
    // =========================================================

    /**
     * @dev Return selected jurors for a dispute.
     */
    function getJurors(uint256 disputeId) external view returns (address[] memory) {
        return disputes[disputeId].jurors;
    }

    /**
     * @dev Return current vote counts for a dispute.
     */
    function getVoteCounts(uint256 disputeId)
        external
        view
        returns (
            uint256 artistVotes,
            uint256 buyerVotes,
            uint256 neitherVotes
        )
    {
        DisputeCase storage d = disputes[disputeId];
        return (d.artistVotes, d.buyerVotes, d.neitherVotes);
    }

    /**
     * @dev Return whether a specific juror voted and what they voted for.
     */
    function getJurorVote(uint256 disputeId, address juror)
        external
        view
        returns (bool hasVoted, VoteOption option)
    {
        DisputeCase storage d = disputes[disputeId];
        return (d.hasVoted[juror], d.voteOf[juror]);
    }

    /**
     * @dev Return all known holders ever registered in the DAO.
     * Useful for debugging and testing.
     */
    function getAllHolders() external view returns (address[] memory) {
        return holders;
    }

    // =========================================================
    //                      INTERNAL HELPERS
    // =========================================================

    /**
     * @dev Add a holder to the registry if not already present.
     */
    function _addHolderIfNeeded(address holder) internal {
        if (!holderExists[holder]) {
            holderExists[holder] = true;
            holders.push(holder);
        }
    }

    /**
     * @dev Move token ownership and keep holder balances in sync.
     *
     * from == address(0) means mint.
     */
    function _moveToken(address from, address to, uint256 tokenId) internal {
        if (from != address(0)) {
            require(tokenOwner[tokenId] == from, "Incorrect owner");
            require(holderBalance[from] > 0, "Insufficient holder balance");
            holderBalance[from]--;
        }

        _addHolderIfNeeded(to);
        holderBalance[to]++;
        tokenOwner[tokenId] = to;
    }

    /**
     * @dev Build the list of eligible juror candidates and their weights.
     *
     * A holder is eligible if:
     * - they are not the DAO treasury
     * - they are not the artist
     * - they are not the buyer
     * - they own at least one DAO NFT
     */
    function _getEligibleCandidates(address artistAddr, address buyerAddr)
        internal
        view
        returns (
            address[] memory candidates,
            uint256[] memory weights,
            uint256 candidateCount,
            uint256 totalWeight
        )
    {
        candidates = new address[](holders.length);
        weights = new uint256[](holders.length);

        for (uint256 i = 0; i < holders.length; i++) {
            address h = holders[i];
            uint256 bal = holderBalance[h];

            if (
                h != address(this) &&
                h != artistAddr &&
                h != buyerAddr &&
                bal > 0
            ) {
                candidates[candidateCount] = h;
                weights[candidateCount] = bal;
                totalWeight += bal;
                candidateCount++;
            }
        }
    }

    /**
     * @dev Return true if user is one of the selected jurors for this dispute.
     */
    function _isJuror(uint256 disputeId, address user) internal view returns (bool) {
        DisputeCase storage d = disputes[disputeId];

        for (uint256 i = 0; i < d.jurors.length; i++) {
            if (d.jurors[i] == user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Return true if every selected juror has already voted.
     */
    function _allJurorsVoted(uint256 disputeId) internal view returns (bool) {
        DisputeCase storage d = disputes[disputeId];

        for (uint256 i = 0; i < d.jurors.length; i++) {
            if (!d.hasVoted[d.jurors[i]]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Determine final outcome from vote counts.
     *
     * Strict highest vote wins.
     * Any tie defaults to Neither.
     */
    function _calculateOutcome(uint256 disputeId) internal view returns (VoteOption) {
        DisputeCase storage d = disputes[disputeId];

        uint256 a = d.artistVotes;
        uint256 b = d.buyerVotes;
        uint256 n = d.neitherVotes;

        if (a > b && a > n) {
            return VoteOption.Artist;
        }

        if (b > a && b > n) {
            return VoteOption.Buyer;
        }

        if (n > a && n > b) {
            return VoteOption.Neither;
        }

        // Tie case
        return VoteOption.Neither;
    }

    receive() external payable {}
}