// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

/**
 * @title Reputation
 * @dev Stores a simple integer reputation score for each address.
 * Positive values mean better reputation, negative values mean worse reputation.
 */
contract Reputation {
    mapping(address => int256) public reputation_score;

    /**
     * @dev Adjust a user's reputation by delta.
     * Example:
     * - delta = +1 => increase reputation
     * - delta = -1 => decrease reputation
     */
    function adjust(address user, int256 delta) external {
        reputation_score[user] += delta;
    }
}