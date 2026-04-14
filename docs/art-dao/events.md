# Events

## Events

**NFT / Auction Events**

* `Minted(uint256 tokenId, address to)`  
   Emitted when a new DAO NFT is minted.  
* `AuctionStarted(uint256 tokenId, uint256 startTime, uint256 endTime)`  
   Emitted when an auction begins.  
* `BidPlaced(uint256 tokenId, address bidder, uint256 amount)`  
   Emitted when a new highest bid is placed.  
* `AuctionSettled(uint256 tokenId, address winner, uint256 amount)`  
   Emitted when an auction is settled.

**Dispute Events**

* `DisputeCreated(uint256 disputeId, address commission, uint256 panelSize)`  
   Emitted when a dispute case is created.  
* `JurorSelected(uint256 disputeId, address juror)`  
   Emitted when a juror is selected.  
* `VoteCast(uint256 disputeId, address juror, VoteOption option)`  
   Emitted when a juror votes.  
* `DisputeResolved(uint256 disputeId, VoteOption outcome)`  
   Emitted when a dispute is resolved.

**Proposal Events**

* `ProposalCreated(uint256 proposalId, address creator, address recipient, uint256 amount, uint256 endTime)`  
   Emitted when a treasury proposal is created.  
* `ProposalVoted(uint256 proposalId, address voter, bool support, uint256 votingPower)`  
   Emitted when a member votes on a proposal.  
* `ProposalExecuted(uint256 proposalId)`  
   Emitted when a proposal is executed.