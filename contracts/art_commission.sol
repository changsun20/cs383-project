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
    
    uint256 upfrontPayment = 0; // mutually agreed initial payment for commission (?)
    //TODO use lastPayment
    uint256 lastPayment = 0 ; // mutually agreed final payments for commission (?)
    uint256 insuranceAmount; // amount parties input in case of passing dispute case to DAO
    uint256 fullPrice;

    //TODO - Cannot dispute before this
    uint256 numberOfDaysToCompletion; // deadline for accept art function?

    IERC721 artwork;
    uint256 artID;

    bool buyerBreakFaith = false;
    bool artistBreakFaith = false;

    bool artistInitiated = true;
    uint256 timeInitiated;


    enum State{Proposed, Confirmed, Funded, WorkCompleted, WorkPayed, Completed, Disputed}
    State public progress;
    
    // buyer payment amount is locked in the contract upon deployment
    constructor(address _buyer, address _artist, uint256 _insuranceAmount, uint256 _price, uint256 _upfrontPayment, uint256 timeframe) {

        // NOTE: CHECK THIS, BUYER AND ARTIST NOT ASSIGNED AT THIS POINT
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

    // Implementation onERC721Received; if sender of nft to contract is not artist, reverts
    function onERC721Received(address operator, address from, uint256 tokenID, bytes calldata data) public override returns (bytes4) {
        require(from == artist, "Artist must input nft");
        return this.onERC721Received.selector;
    }

    //this confirms the parameters set in the constructor are ok with the other party
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

    //Once the contract has been confirmed by both parties, add funds to the contract
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

    //the artist submits work to the commission contract
    function acceptArt(address nft, uint256 tokenID) external onlyArtist {
        IERC721 _artwork = IERC721(nft); // temp IERC271(nft) to avoid storing before require checks

        require(progress == State.Funded, "Contract has not been funded by both parties");
        require(_artwork.ownerOf(tokenID) == msg.sender, "Sender is not owner of the nft");

        // artist must have already approved this contract to recieve the nft
        // such as IERC721(nft).approve(address(our contract), tokenId);

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
}
