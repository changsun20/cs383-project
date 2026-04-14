# Invariants

## Invariants

* DAO NFT ownership is tracked by `tokenOwner`, and each token has exactly one owner at a time.  
* `holderBalance[address]` must always equal the number of DAO NFTs currently owned by that address.  
* `totalSupply` only increases when a new DAO NFT is minted.  
* The contract treasury itself (`address(this)`) may temporarily hold DAO NFTs that are waiting to be auctioned.  
* Only one active dispute may exist at a time for a given `ArtCommission` contract.  
* A dispute cannot be resolved before jurors are selected.  
* A juror may vote at most once in a given dispute.  
* Only selected jurors may vote in a dispute.  
* Voting power for disputes and treasury proposals is proportional to the voter’s current DAO NFT balance.  
* Dispute outcomes are limited to exactly three possibilities: `Artist`, `Buyer`, or `Neither`.  
* A resolved dispute cannot be resolved again.  
* A proposal can only be executed once.  
* Proposal execution is only allowed after the proposal voting period has ended and the support threshold has been met.  
* ETH held in the DAO treasury may only leave the contract through:  
  * refunding a previous highest bidder in an auction,  
  * paying juror rewards during dispute resolution,  
  * executing a successful treasury proposal.