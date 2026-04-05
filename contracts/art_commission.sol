pragma solidity ^0.8.26;

// Import this file to use console.log
import "hardhat/console.sol";

contract ArtCommision {
    address public payable artist;
    address public payable buyer;
    uint256 upfrontPaymentPercent;
    uint256 lastPayamentPercent;
    unit256 insuranceAmount;
    uint256 fullPrice;

    enum StateOfProgressP{InitialAgreement, InProgress, WorkCompleted, WorkPayed, Completed, Disputed}
    StateOfProgress public progressTracker
    
    //The artist creates the work but the buyer must confirm initial agreement to set inProgress? or other way around
    constructor(uint256 inuranceAmoung, uint256 price, uint256 upfrontPaymentPercent) {
        buyer = payable(msg.sender)
        //check that the value sent is the upfront percent of the total price price is 
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
    }

    //this confirms the parameters set in the constructor are ok with the other party
    function buyerConfirm() {

    }

    function vault() {

    }

    function raiseDispute() onlyParties {

    }
}