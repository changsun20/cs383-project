pragma solidity ^0.8.26;

// Import this file to use console.log
import "hardhat/console.sol";

contract ArtCommision {
    address payable artist;
    address payable buyer;
    uint256 upfrontPaymentPercent;
    uint256 lastPayamentPercent;
    unit256 insuranceAmount;

    constructor() {

    }

    modifier onlyArtist() {
        require(msg.sender == artist, "Not artist")
        _;
    }

    modifer onlyBuyer() {
        require(msg.sender == buyer, "Not buyer") 
        _;
    }

    function vault() {

    }

    function raiseDispute() {

    }
}