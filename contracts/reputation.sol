pragma solidity ^0.8.26;

contract Reputation {
    //reputation must be a integer which can be negative 
    mapping(address => int256) public  reputation_score;

    function adjust(address user, int256 delta) external {
        reputation_score[user] += delta;
    }

}