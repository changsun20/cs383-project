// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

// Import this file to use console.log
import "hardhat/console.sol";

// referencing functions from OpenZeppelin ERC721 contracts
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenID) external; // safely transfers ERC721 for both EOA and contract addresses
    function approve(address to, uint256 tokenID) external; // required for safeTransfer involving a contract, approves "to" address as recipient
    function ownerOf(uint256 tokenID) external view returns (address);
}

contract ArtCommission {
    //ALL PRICES IN WEI!!
    address public artist;
    address public buyer;
    uint256 upfrontPaymentPercent;
    uint256 lastPaymentPercent;
    uint256 insuranceAmount;
    uint256 fullPrice;
    uint256 numberOfDaysToCompletion;
    IERC721 artwork;
    uint256 artID;

    enum State{Proposed, Confirmed, WorkCompleted, WorkPayed, Completed, Disputed}
    State public progress;
    
    // buyer payment amount is locked in the contract upon deployment
    constructor(uint256 _insuranceAmount, uint256 price, uint256 _upfrontPaymentPercent, uint256 timeframe) payable {
        //The buyer will construct the contract
        buyer = payable(msg.sender);

        //require the amount of insurance to be more than .015 ETH in total, about .075 or $15 per party
        require(_insuranceAmount > 7500000000000000, "Insurance too low");
        insuranceAmount = _insuranceAmount;
        upfrontPaymentPercent = _upfrontPaymentPercent;
        fullPrice = price;
        numberOfDaysToCompletion = timeframe;
        lastPaymentPercent = 100 - upfrontPaymentPercent;

        //check that the value sent is the upfront percent of the total price price and the insurance amount
        uint256 upfrontPayment = price * upfrontPaymentPercent / 100;
        require(msg.value == upfrontPayment + insuranceAmount);

        progress = State.Proposed;

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

    //this confirms the parameters set in the constructor are ok with the other party
    function artistConfirm() external payable onlyArtist {
        require(msg.value == insuranceAmount, "Insurance too low");
        
        //set the state to confirmed
        progress = State.Confirmed;
    }

    //the artist submits work to the commission contract
    function acceptArt(address nft, uint256 tokenID) external onlyArtist {
        require(progress == State.Confirmed, "Contract has not been accepted by both parties")
        artwork = IERC721(nft);
        artID = tokenID;

        require(artwork.ownerOf(tokenID) == artist, "Artist is not owner of the nft");

        // artist must have already approved this contract to recieve the nft
        //TODO: does safeTransferFrom require onERC721Received() to be implemented?
        artwork.safeTransferFrom(msg.sender, address(this), tokenID);

        progress = State.WorkCompleted;
    }

    //the buyer pays for work, work and payment are released
    function payInFullAndRelease() external onlyBuyer {
        
        //check that the msg.value is a payment in full
        require(msg.value/100 == lastPaymentPercent, "Not the expected final payment")
        require(progress == State.WorkCompleted, "Artwork not submitted")
  
        progress = State.Completed;

        //Transfer the work to the buyer
        artwork.safeTransferFrom(address(this), msg.sender, artID);

        //transfer the payment to the artist
        artist.transfer(price)

        //TODO: do we return the insurance or some portion of the insurance? 
    }

    //update the trust score of buyer and artist
    function updateTrustworthiness() external {
        //TODO
    }

    function raiseDispute() external onlyParties {

        progress = State.Disputed;

        //TODO:deal with the DAO contract
    }
}