pragma solidity ^0.8.26;

// Import this file to use console.log
import "hardhat/console.sol";

// referencing functions from OpenZeppelin ERC721 contracts
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenID) external; // safely transfers ERC721 for both EOA and contract addresses
    function approve(address to, uint256 tokenID) external; // required for safeTransfer involving a contract, approves "to" address as recipient
}

contract ArtCommission {
    //ALL PRICES IN WEI!!
    address public payable artist;
    address public payable buyer;
    uint256 upfrontPaymentPercent;
    uint256 lastPaymentPercent;
    unit256 insuranceAmount;
    uint256 fullPrice;
    uint256 numberOfDaysToCompletion;
    IERC721 artwork;

    enum State{Proposed, Confirmed, WorkCompleted, WorkPayed, Completed, Disputed}
    StateOfProgress public progress;
    
    // buyer payment amount is locked in the contract upon deployment
    constructor(uint256 inuranceAmount, uint256 price, uint256 upfrontPaymentPercent, uint256 timeframe) payable {
        //The buyer will construct the contract
        buyer = payable(msg.sender);

        //require the amount of insurance to be more than .015 ETH in total, about .075 or $15 per party
        require(insuranceAmount > 7500000000000000, "Insurance too low");

        //check that the value sent is the upfront percent of the total price price is 
        uint256 upfrontPayment = price*(1/upfrontPaymentPercent);
        require(msg.value == upfrontPayment + insuranceAmount);

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
        require(msg.sender == buyer || msg.sender == artist, "Not involved party")
        _;
    }

    //this confirms the parameters set in the constructor are ok with the other party
    function artistConfirm() onlyArtist {
        require(msg.value == insuranceAmount, "Insurance too low")
        
        //set the state to confirmed
        progress = State.Confirmed;
    }

    //the artist submits work to the commission contract
    function acceptArt(address nft, uint256 tokenID) onlyArtist {
        artwork = IERC721(nft);

        require(artwork.ownerOf(tokenID) == artist, "Artist is not owner of the nft");

        // artist must have already approved this contract to recieve the nft
        artwork.safeTransferFrom(msg.sender, address(this), tokenID);

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