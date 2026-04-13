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

    // payments
    uint256 public fullPrice;
    uint256 public upfrontPayment;
    uint256 public lastPayment;
    uint256 public insurance;

    // commission artwork details
    uint256 public artID;
    IERC721 public artwork;

    // commission participants
    address public immutable artist;
    address public immutable buyer;
    address public immutable DAO;

    bool artistInitiated;

    // Mutual cancellation approvals
    bool buyerBreakFaith;
    bool artistBreakFaith;

    // Dispute info
    uint256 public disputeId;
    bool public daoCaseCreated;

    // Commission timeline variables
    uint timeInitiated;
    uint numberOfDaysToCompletion; // grace period for artist to complete work

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
    constructor(address _buyer, address _artist, uint256 _insuranceAmount, uint256 _price, uint256 _upfrontPayment, uint256 timeframe, address _dao) {

        //check that the buyer or the artist is creating the contract
        require(msg.sender == _buyer || msg.sender == _artist, "Third party cannot initiate contract");
        require(_buyer != address(0), "Invalid buyer");
        require(_artist != address(0), "Invalid artist");
        require(_dao != address(0), "Invalid DAO");
        
        //require the amount of insurance to be more than .015 ETH in total, about .075 or $15 per party
        require(_insuranceAmount >= 7500000000000000, "Insurance too low");
        require(_price >= _upfrontPayment, "Upfront exceeds full price");

        buyer = _buyer;
        artist = _artist;
        DAO = _dao;

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
    function onERC721Received(address operator, address from, uint256 tokenID, bytes calldata data) public override returns (bytes4) {
        require(from == artist, "Artist must input art nft");
        require(operator == address(this), "Commission contract is not the art nft recipient");
        return this.onERC721Received.selector;
    }

    // =========================================================
    //                     COMMISSION LIFECYCLE
    // =========================================================

    /**
     * @dev The party who did not deploy the contract must confirm the commission.
     */
    function contractConfirm() external onlyParties {
        require(progress == State.Proposed, "Commission proposal details not yet approved by both parties");

        if (artistInitiated == false) {
            require(msg.sender == artist, "Artist must approve proposed commission");
        } else {
            require(msg.sender == buyer, "Buyer must approve proposed commission");
        }

        progress = State.Confirmed;
        emit ContractConfirmed(msg.sender);

        timeInitiated = block.timestamp;
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
    function fund() public onlyParties payable {
        require(progress == State.Confirmed, "Contract has not been confirmed by both parties");

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

        emit Funded(msg.sender, msg.value);
    }

    /**
     * @dev The artist submits the NFT artwork after both parties have funded.
     */
    function acceptArt(address nft, uint256 tokenID) external onlyArtist {
        require(progress == State.Funded, "Contract has not been funded by both parties");

        IERC721 _artwork = IERC721(nft);
        require(_artwork.ownerOf(tokenID) == msg.sender, "Sender is not owner of the nft");

        // Deposit NFT to contract for escrow
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
        require(msg.value == lastPayment , "Not the expected full final payment");

        // Transfer the artwork to the buyer.
        artwork.safeTransferFrom(address(this), msg.sender, artID);

        //transfer the payment to the artist
        payable(artist).transfer(msg.value + upfrontPayment + (insuranceAmount/2));
        payable(buyer).transfer(insuranceAmount/2);

        progress = State.Completed;

        emit CompletedSuccessfully(buyer, artist);
    }

    /**
     * @dev If both parties agree to cancel, return funds and artwork safely.
     */
    function goodFaithRelease() public onlyParties {
        if (msg.sender == buyer) {
            buyerBreakFaith = true;
        }

        if (msg.sender == artist) {
            artistBreakFaith = true;
        }

        require(buyerBreakFaith == true && artistBreakFaith == true, "Both parties must approve cancellation");

        // if funds to return
        if (address(this).balance > 0 && artwork.ownerOf(artID) != address(this)) {
            payable(buyer).transfer(upfrontPayment);

            payable(artist).transfer(insuranceAmount/2);
            payable(buyer).transfer(insuranceAmount/2);
        
        } else if (address(this).balance > 0 && artwork.ownerOf(artID) == address(this)) {
            artwork.safeTransferFrom(address(this), artist, artID);
            payable(artist).transfer(upfrontPayment);

            payable(artist).transfer(insuranceAmount/2);
            payable(buyer).transfer(insuranceAmount/2);
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

        uint elapsedDays = (block.timestamp - timeInitiated) / 1 days;  // current time - time commission initiated
        require(elapsedDays > numberOfDaysToCompletion, "Must leave time before transaction can be disputed");
        
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
     */
    function artistWins() public onlyDAO payable {
        require(progress == State.Disputed, "Voting outcome only applicable for disputed commissions");

        if (artwork.ownerOf(artID) == address(this)) {
            artwork.safeTransferFrom(address(this), artist, artID);
        }

        payable(artist).transfer(insuranceAmount / 2);
        payable(DAO).transfer(insuranceAmount / 2);

        progress = State.Completed;

        emit ResolvedByDAO("Artist");
    }

    /**
     * @dev DAO resolves in favor of the buyer.
     *
     * Example policy:
     * - If artwork exists in escrow, transfer it to buyer.
     * - Buyer gets one insurance half.
     * - DAO gets the other insurance half.
     */
    function buyerWins() public onlyDAO payable {
        require(progress == State.Disputed, "Voting outcome only applicable for disputed commissions");

        if (artwork.ownerOf(artID) == address(this)) {
            artwork.safeTransferFrom(address(this), buyer, artID);
        }

        payable(buyer).transfer(insuranceAmount / 2);
        payable(DAO).transfer(insuranceAmount / 2);

        progress = State.Completed;

        emit ResolvedByDAO("Buyer");
    }

    /**
     * @dev DAO resolves that neither side wins.
     *
     * Example policy:
     * - If artwork exists, return it to artist.
     * - Refund buyer's payment if still locked.
     * - DAO receives insurance.
     */
    function neitherWins() public onlyDAO payable {
        require(progress == State.Disputed, "Voting outcome only applicable for disputed commissions");

        if (artwork.ownerOf(artID) == address(this)) {
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

        emit ResolvedByDAO("Neither");
    }

    receive() external payable {}
}
