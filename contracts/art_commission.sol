// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

// Import this file to use console.log
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// inherit IERC271Reciever & implement onERC721Received to enable smart contract to recieve nft with safeTransferFrom
contract ArtCommission is IERC721Receiver {
    //ALL PRICES IN WEI!!
    // commission participants
    address public artist;
    address public buyer;
    address public DAO;
    
    // commission payments
    uint256 upfrontPayment = 0; // mutually agreed initial payment for commission
    //TODO use lastPayment
    uint256 lastPayment = 0 ; // mutually agreed final payment for commission
    uint256 insuranceAmount; // amount parties input in case of passing dispute case to DAO
    uint256 fullPrice;

    // commission artwork details
    IERC721 artwork;
    uint256 artID;

    // do the time vars need to be uint256? (for efficient byte slot packing...?)
    uint256 timeInitiated;
    //TODO - Cannot dispute before this
    uint256 numberOfDaysToCompletion; // deadline for accept art function?

    bool artistInitiated;
    // each party's decision state regarding commission cancellation
    bool buyerBreakFaith;
    bool artistBreakFaith;

    // commission progress states
    enum State{Proposed, Confirmed, Funded, WorkCompleted, WorkPayed, Completed, Disputed}
    State public progress;

    // need to work out events and remember to add emits to functions
    //event CommissionProposed(address artist, address buyer, address contract);
    //event CommissionConfirmed();
    //event CommissionFunded(uint256 insuranceAmount, uint256 upfrontPayment, uint256 amount); // amount should be address(this).balance
    //event ArtSubmitted(address artwork, uint256 artID);
    //event Finalized();
    //event Disputed();
    //event MutualCancellation();
    
    // A buyer or artist initiates the commission contract and proposes an insurance amount each party needs to contribute,
    // a total price the buyer will pay for the commission, an upfront payment amount the buyer will pay for the work
    // (which is locked in the contract alongside the NFT artwork), and a deadline for the commission to be completed
    constructor(address _buyer, address _artist, uint256 _insuranceAmount, uint256 _price, uint256 _upfrontPayment, uint256 timeframe) {

        //check that the buyer or the artist is creating the contract
        require(msg.sender == _buyer || msg.sender == _artist, "Third party cannot initiate contract");
        
        //require the amount of insurance to be more than .015 ETH in total, about .075 or $15 per party
        require(_insuranceAmount > 7500000000000000, "Insurance too low");

        buyer = _buyer;
        artist = _artist;
        insuranceAmount = _insuranceAmount;
        upfrontPayment = _upfrontPayment;
        lastPayment = _price - upfrontPayment;
        fullPrice = _price;
        numberOfDaysToCompletion = timeframe;
    
        progress = State.Proposed;

        //check if the buyer or the artist will need to confirm the contract
        if (buyer == msg.sender) {
            artistInitiated = false;
        } else {
            artistInitiated = true;
        }

    }

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

    // Implementation onERC721Received; if the individual sending an NFT to the contract is not the artist, the transfer reverts
    function onERC721Received(address operator, address from, uint256 tokenID, bytes calldata data) public override returns (bytes4) {
        require(from == artist, "Artist must input nft");
        return this.onERC721Received.selector;
    }

    // For the commission to progress, the party who did not deploy the commission must confirm
    // the proposed price and deadline details
    function contractConfirm() external onlyParties payable {
        //the party who did not propose the contract must confirm the project
        if (artistInitiated == false) {
            require(msg.sender == artist);
        } else {
            require(msg.sender == buyer);
        }

        //set the state to confirmed
        progress = State.Confirmed;
    }

    // Once the commission's details are approved by both parties, they each fund the contract with half of the insurance amount.
    // The buyer additionally funds the contract with the agreed upfront payment amount, which is locked in the contract until
    // the final exchange of the artwork and commission payment.
    function fund() public onlyParties payable {
        require(progress == State.Confirmed, "Contract has not been confirmed by both parties");

        if (msg.sender == artist) {
            require(msg.value == insuranceAmount/2, "Did not send insurance value");
        }

        if (msg.sender == buyer) {
            require(msg.value == (insuranceAmount/2) + upfrontPayment, "Did not pay insurance and deposit");
        }

        if (payable(address(this)).balance == (upfrontPayment + insuranceAmount)) {
            progress = State.Funded;
        }
    }

    // The artist submits their work to the commission contract, prior to this, the artist must have approved the contract as
    // a recipient of an NFT (i.e. IERC721(nft).approve(address(commission_contract), tokenId))
    function acceptArt(address nft, uint256 tokenID) external onlyArtist {
        IERC721 _artwork = IERC721(nft); // temp IERC271(nft) to avoid storing before require checks

        require(progress == State.Funded, "Contract has not been funded by both parties");
        require(_artwork.ownerOf(tokenID) == msg.sender, "Sender is not owner of the nft");

        // transfer nft from sender to this contract
        _artwork.safeTransferFrom(msg.sender, address(this), tokenID);

        // store nft details
        artwork = _artwork;
        artID = tokenID;

        // update progress state
        progress = State.WorkCompleted;
    }

    //locked funds from buyer go to artist, locked artwork goes to buyer
    function payInFullAndRelease() external onlyBuyer payable {
        require(progress == State.WorkCompleted, "Artwork not submitted");
        //check that the msg.value is a payment in full
        require(msg.value + upfrontPayment == fullPrice , "Not the expected full final payment");

        //Transfer the work to the buyer
        artwork.safeTransferFrom(address(this), msg.sender, artID);
        //transfer the payment to the artist
        payable(artist).transfer(fullPrice);

        payable(artist).transfer(insuranceAmount/2);
        payable(buyer).transfer(insuranceAmount/2);
        progress = State.Completed;
    }

    //update the trust score of buyer and artist
    function updateTrustworthiness() external {
        //TODO -- extra/if time
        //reputation would have to be its own contract with a mapping that is called by commission contracts
    }

    // If both parties agree to cancel the commission, the contract returns what they have funded
    function goodFaithRelease() public onlyParties {
        if (msg.sender == buyer) {
            buyerBreakFaith = true;
        }
        if (msg.sender == artist) {
            artistBreakFaith = true;
        }

        require(buyerBreakFaith == true && artistBreakFaith == true, "Buyer or artist has not approved of goodFaithRelease");

        // return art
        artwork.safeTransferFrom(address(this), artist, artID);

        // return locked funds to buyer
        payable(buyer).transfer(fullPrice); // or should it just be a portion of the price? and some wei to artist?
        payable(artist).transfer(insuranceAmount/2);
        payable(buyer).transfer(insuranceAmount/2);
    }

    function raiseDispute() public onlyParties {
        //set some time requirement before someone can raise a dispute
        progress = State.Disputed;

        //TODO:deal with the DAO contract
        payable(buyer).transfer(buyerRefund);
        payable(artist).transfer(artistRefund);
    }

    // skeleton DAO result options -- sorry...kind of put some code based on what we discussed monday
    // BUT feel free to change in accordance to the DAO contract implementation

    // logic of DAO voting outcome 1: jury decides the artist wins the dispute
    function artistWins() public onlyDAO payable {
        require(progress = State.Disputed, "Voting outcome only applicable for disputed commissions");

        if (artwork != address(0)) {
            artwork.safeTransferFrom(address(this), artist, artID);
        }
        payable(artist).transfer(insuranceAmount/2);
        payable(DAO).transfer(insuranceAmount/2); // buyer's insurance goes to DAO

        progress = State.Completed
    }

    // logic of DAO voting outcome 2: jury decides the buyer wins the dispute
    function buyerWins() public onlyDAO payable {
        require(progress = State.Disputed, "Voting outcome only applicable for disputed commissions");

        if (artwork != address(0)) {
            artwork.safeTransferFrom(address(this), buyer, artID);
        }
        payable(buyer).transfer(insuranceAmount/2);
        payable(DAO).transfer(insuranceAmount/2); // artist's insurance goes to DAO

        progress = State.Completed
    }

    // logic of DAO voting outcome 3: jury decides neither party wins dispute
    function neitherWins() public onlyDAO payable {
        require(progress = State.Disputed, "Voting outcome only applicable for disputed commissions");

        if (artwork != address(0)) {
            artwork.safeTransferFrom(address(this), artist, artID);
        }
        payable(buyer).transfer(fullPrice);
        payable(DAO).transfer(insuranceAmount);

        progress = State.Completed
    }
}
