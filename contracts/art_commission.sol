pragma solidity ^0.8.26;

// Import this file to use console.log
import "hardhat/console.sol";

contract ArtCommision {
    //ALL PRICES IN WEI!!
    address public payable artist;
    address public payable buyer;
    uint256 upfrontPaymentPercent;
    uint256 lastPayamentPercent;
    unit256 insuranceAmount;
    uint256 fullPrice;
    uint256 numberOfDaysToCompletion;

    enum State{Proposed, Confirmed, WorkCompleted, WorkPayed, Completed, Disputed}
    StateOfProgress public progress;
    
    constructor(uint256 inuranceAmoung, uint256 price, uint256 upfrontPaymentPercent, uint256 timeframe) {
        //The buyer will construct the contract
        buyer = payable(msg.sender)

        //require the amount of insurance to be more than .015 ETH in total, about .075 or $15 per party
        require(insuranceAmount > 7500000000000000, "Insurance too low")

        //check that the value sent is the upfront percent of the total price price is 
        uint256 upfrontPayment = price*(1/upfrontPaymentPercent)
        require(msg.value == upfrontPayment + insuranceAmount)

        progress = State.Proposed;

    }

    modifier onlyArtist() {
        require(msg.sender == artist, "Not artist")
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer") 
        _;
    }

    modifier onlyParties() {
        require(msg.sender == buyer | msg.sender == artist, "Not involved party")
        _;
    }


    //this confirms the parameters set in the constructor are ok with the other party
    function artistConfirm() onlyArtist {
        require(msg.value == insuranceAmount, "Insurance too low")
        
        //set the state to confirmed
        progress = State.Confirmed;
    }

    //the artist submits work, IKD how to accept ERC721
    function acceptArt(address art) {
        progress = State.WorkCompleted;
    }

    //the buyer pays for work, work and payment are released
    function payInFullAndRelease() onlyBuyer {

        progress = State.Complete;
    }

    //update the trust score of buyer and artist
    function updateTrustworthiness() {

    }

    function raiseDispute() onlyParties {

        progress = State.Disputed;
    }
}