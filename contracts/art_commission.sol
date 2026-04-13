// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev Interface used to communicate with the DAO contract.
 */
interface IArtDAO {
    function createDisputeCase(
        address commission,
        uint256 panelSize,
        uint256 votingDuration
    ) external returns (uint256);
}

/**
 * @dev Interface used to communicate with the reputation contract.
 */
interface IReputation {
    function adjust(address user, int256 delta) external;
}

/**
 * @title ArtCommission
 * @dev Handles the lifecycle of one commission between a buyer and an artist.
 *
 * Main flow:
 * 1. One party deploys the contract.
 * 2. The other party confirms it.
 * 3. Both parties fund insurance, and buyer funds upfront payment.
 * 4. Artist submits NFT artwork.
 * 5. Buyer pays remaining amount and receives NFT.
 * 6. If there is a dispute, DAO jurors vote and the DAO resolves it.
 */
contract ArtCommission is IERC721Receiver {
    // =========================================================
    //                         STORAGE
    // =========================================================

    // Participants
    address public artist;
    address public buyer;
    address public DAO;

    // External helper contracts
    IReputation public reputation;

    // Payments
    uint256 public upfrontPayment;
    uint256 public lastPayment;
    uint256 public insuranceAmount;
    uint256 public fullPrice;

    // Artwork details
    IERC721 public artwork;
    uint256 public artID;

    // Timing
    uint256 public timeInitiated;
    uint256 public numberOfDaysToCompletion;

    // Contract creation direction
    bool public artistInitiated;

    // Mutual cancellation approvals
    bool public buyerBreakFaith;
    bool public artistBreakFaith;

    // Dispute info
    uint256 public disputeId;
    bool public daoCaseCreated;

    // Commission progress
    enum State {
        Proposed,
        Confirmed,
        Funded,
        WorkCompleted,
        Completed,
        Disputed
    }

    State public progress;

    // =========================================================
    //                          EVENTS
    // =========================================================

    event ContractConfirmed(address confirmer);
    event Funded(address funder, uint256 amount);
    event ArtworkSubmitted(address nft, uint256 tokenId);
    event CompletedSuccessfully(address buyer, address artist);
    event GoodFaithCancelled();
    event DisputeRaised(uint256 disputeId);
    event ResolvedByDAO(string outcome);

    // =========================================================
    //                        CONSTRUCTOR
    // =========================================================

    /**
     * @dev Deploy a commission contract.
     *
     * @param _buyer Buyer address
     * @param _artist Artist address
     * @param _dao DAO contract address
     * @param _reputation Reputation contract address
     * @param _insuranceAmount Total insurance amount locked in the contract
     * @param _price Total commission price
     * @param _upfrontPayment Upfront payment included in buyer's funding
     * @param timeframe Time allowed before dispute can be raised
     */
    constructor(
        address _buyer,
        address _artist,
        address _dao,
        address _reputation,
        uint256 _insuranceAmount,
        uint256 _price,
        uint256 _upfrontPayment,
        uint256 timeframe
    ) {
        require(msg.sender == _buyer || msg.sender == _artist, "Third party cannot initiate contract");
        require(_buyer != address(0), "Invalid buyer");
        require(_artist != address(0), "Invalid artist");
        require(_dao != address(0), "Invalid DAO");
        require(_reputation != address(0), "Invalid reputation");
        require(_insuranceAmount > 7500000000000000, "Insurance too low");
        require(_price >= _upfrontPayment, "Upfront exceeds full price");

        buyer = _buyer;
        artist = _artist;
        DAO = _dao;
        reputation = IReputation(_reputation);

        insuranceAmount = _insuranceAmount;
        upfrontPayment = _upfrontPayment;
        lastPayment = _price - upfrontPayment;
        fullPrice = _price;

        numberOfDaysToCompletion = timeframe;
        timeInitiated = block.timestamp;

        progress = State.Proposed;

        // Track who initiated the contract.
        if (buyer == msg.sender) {
            artistInitiated = false;
        } else {
            artistInitiated = true;
        }
    }

    // =========================================================
    //                         MODIFIERS
    // =========================================================

    modifier onlyArtist() {
        require(msg.sender == artist, "Not artist");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer");
        _;
    }

    modifier onlyParties() {
        require(msg.sender == buyer || msg.sender == artist, "Not involved party");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == DAO, "Not involved DAO");
        _;
    }

    // =========================================================
    //                    ERC721 RECEIVER LOGIC
    // =========================================================

    /**
     * @dev Allows this contract to receive NFT artwork via safeTransferFrom.
     * Only the artist is allowed to send the NFT in.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenID,
        bytes calldata data
    ) public override returns (bytes4) {
        require(from == artist, "Artist must input nft");
        return this.onERC721Received.selector;
    }

    // =========================================================
    //                     COMMISSION LIFECYCLE
    // =========================================================

    /**
     * @dev The party who did not deploy the contract must confirm the commission.
     */
    function contractConfirm() external onlyParties {
        require(progress == State.Proposed, "Invalid state");

        if (artistInitiated == false) {
            require(msg.sender == artist, "Artist must confirm");
        } else {
            require(msg.sender == buyer, "Buyer must confirm");
        }

        progress = State.Confirmed;
        emit ContractConfirmed(msg.sender);
    }

    /**
     * @dev Both parties fund insurance, and buyer also funds the upfront payment.
     *
     * Artist sends:
     * - insuranceAmount / 2
     *
     * Buyer sends:
     * - insuranceAmount / 2 + upfrontPayment
     */
    function fund() external onlyParties payable {
        require(progress == State.Confirmed, "Contract not confirmed");

        if (msg.sender == artist) {
            require(msg.value == insuranceAmount / 2, "Wrong artist funding");
        }

        if (msg.sender == buyer) {
            require(msg.value == (insuranceAmount / 2) + upfrontPayment, "Wrong buyer funding");
        }

        emit Funded(msg.sender, msg.value);

        // Move to Funded state once the contract holds exactly:
        // upfront payment + total insurance
        if (address(this).balance == (upfrontPayment + insuranceAmount)) {
            progress = State.Funded;
        }
    }

    /**
     * @dev The artist submits the NFT artwork after both parties have funded.
     */
    function acceptArt(address nft, uint256 tokenID) external onlyArtist {
        require(progress == State.Funded, "Contract not funded");

        IERC721 _artwork = IERC721(nft);
        require(_artwork.ownerOf(tokenID) == msg.sender, "Sender not owner of NFT");

        // Transfer NFT into escrow.
        _artwork.safeTransferFrom(msg.sender, address(this), tokenID);

        artwork = _artwork;
        artID = tokenID;

        progress = State.WorkCompleted;

        emit ArtworkSubmitted(nft, tokenID);
    }

    /**
     * @dev Buyer pays the remaining amount, receives the artwork,
     * and both parties receive back their insurance halves.
     */
    function payInFullAndRelease() external onlyBuyer payable {
        require(progress == State.WorkCompleted, "Artwork not submitted");
        require(msg.value == lastPayment, "Wrong final payment");

        // Transfer the artwork to the buyer.
        artwork.safeTransferFrom(address(this), msg.sender, artID);

        // Transfer full commission payment to the artist.
        // The contract already holds upfrontPayment, and buyer now sent lastPayment.
        payable(artist).transfer(fullPrice);

        // Return insurance to both parties.
        payable(artist).transfer(insuranceAmount / 2);
        payable(buyer).transfer(insuranceAmount / 2);

        progress = State.Completed;

        // Successful completion: both sides get positive reputation.
        reputation.adjust(artist, 1);
        reputation.adjust(buyer, 1);

        emit CompletedSuccessfully(buyer, artist);
    }

    /**
     * @dev If both parties agree to cancel, return funds and artwork safely.
     */
    function goodFaithRelease() external onlyParties {
        require(
            progress == State.Confirmed ||
            progress == State.Funded ||
            progress == State.WorkCompleted,
            "Invalid state"
        );

        if (msg.sender == buyer) {
            buyerBreakFaith = true;
        }

        if (msg.sender == artist) {
            artistBreakFaith = true;
        }

        require(
            buyerBreakFaith && artistBreakFaith,
            "Both parties must approve cancellation"
        );

        // If the artwork has already been submitted, return it to the artist.
        if (address(artwork) != address(0)) {
            artwork.safeTransferFrom(address(this), artist, artID);
        }

        // Refund buyer's payment if it is locked in the contract.
        if (address(this).balance >= upfrontPayment) {
            payable(buyer).transfer(upfrontPayment);
        }

        // Return insurance halves if available.
        uint256 remainingBalance = address(this).balance;

        if (remainingBalance >= insuranceAmount) {
            payable(artist).transfer(insuranceAmount / 2);
            payable(buyer).transfer(insuranceAmount / 2);
        }

        progress = State.Completed;

        emit GoodFaithCancelled();
    }

    // =========================================================
    //                         DISPUTE FLOW
    // =========================================================

    /**
     * @dev Raise a dispute after the agreed completion window has passed.
     *
     * @param panelSize Number of jurors to be selected by the DAO.
     * @param votingDuration Voting period in seconds inside the DAO.
     */
    function raiseDispute(uint256 panelSize, uint256 votingDuration) external onlyParties {
        require(
            progress == State.Funded || progress == State.WorkCompleted,
            "Cannot dispute in current state"
        );
        require(!daoCaseCreated, "Dispute already raised");

        uint256 elapsedDays = (block.timestamp - timeInitiated) / 1 days;
        require(
            elapsedDays > numberOfDaysToCompletion,
            "Must wait until completion period passes"
        );

        progress = State.Disputed;

        // Ask the DAO to create the dispute case.
        disputeId = IArtDAO(DAO).createDisputeCase(address(this), panelSize, votingDuration);
        daoCaseCreated = true;

        emit DisputeRaised(disputeId);
    }

    /**
     * @dev DAO resolves in favor of the artist.
     *
     * Example policy:
     * - If artwork exists in escrow, return it to artist.
     * - Artist receives their own insurance half.
     * - DAO receives buyer's insurance half as penalty / arbitration pool.
     * - Reputation updates accordingly.
     */
    function artistWins() external onlyDAO {
        require(progress == State.Disputed, "Not disputed");

        if (address(artwork) != address(0)) {
            artwork.safeTransferFrom(address(this), artist, artID);
        }

        payable(artist).transfer(insuranceAmount / 2);
        payable(DAO).transfer(insuranceAmount / 2);

        progress = State.Completed;

        reputation.adjust(artist, 1);
        reputation.adjust(buyer, -1);

        emit ResolvedByDAO("Artist");
    }

    /**
     * @dev DAO resolves in favor of the buyer.
     *
     * Example policy:
     * - If artwork exists in escrow, transfer it to buyer.
     * - Buyer gets one insurance half.
     * - DAO gets the other insurance half.
     * - Reputation updates accordingly.
     */
    function buyerWins() external onlyDAO {
        require(progress == State.Disputed, "Not disputed");

        if (address(artwork) != address(0)) {
            artwork.safeTransferFrom(address(this), buyer, artID);
        }

        payable(buyer).transfer(insuranceAmount / 2);
        payable(DAO).transfer(insuranceAmount / 2);

        progress = State.Completed;

        reputation.adjust(buyer, 1);
        reputation.adjust(artist, -1);

        emit ResolvedByDAO("Buyer");
    }

    /**
     * @dev DAO resolves that neither side wins.
     *
     * Example policy:
     * - If artwork exists, return it to artist.
     * - Refund buyer's payment if still locked.
     * - DAO receives insurance.
     * - Both reputations decrease.
     */
    function neitherWins() external onlyDAO {
        require(progress == State.Disputed, "Not disputed");

        if (address(artwork) != address(0)) {
            artwork.safeTransferFrom(address(this), artist, artID);
        }

        // Refund buyer's locked payment if still in contract.
        uint256 bal = address(this).balance;

        if (bal >= fullPrice) {
            payable(buyer).transfer(fullPrice);
            payable(DAO).transfer(insuranceAmount);
        } else {
            // If fullPrice is not fully available, send what remains according to current policy.
            // This keeps the demo contract from reverting due to insufficient balance.
            if (address(this).balance >= insuranceAmount) {
                payable(DAO).transfer(insuranceAmount);
            }
        }

        progress = State.Completed;

        reputation.adjust(buyer, -1);
        reputation.adjust(artist, -1);

        emit ResolvedByDAO("Neither");
    }

    receive() external payable {}
}
