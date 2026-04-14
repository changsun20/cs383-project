# State Variables

## State variables: 

**DAO timing and ID tracking**

* **`MINT_INTERVAL (uint256 constant)`**  
   Minimum amount of time required between DAO NFT mints.  
* **`AUCTION_DURATION (uint256 constant)`**  
   Fixed duration of each DAO NFT auction.  
* **`JURY_REWARD (uint256 constant)`**  
   Fixed ETH reward paid to each juror who voted in a dispute.  
* **`lastMintTime (uint256)`**  
   Timestamp of the last DAO NFT mint.  
* **`nextTokenId (uint256)`**  
   ID to assign to the next minted DAO NFT.  
* **`nextDisputeId (uint256)`**  
   ID to assign to the next dispute case.  
* **`nextProposalId (uint256)`**  
   ID to assign to the next treasury proposal.  
* **`totalSupply (uint256)`**  
   Total number of DAO NFTs ever minted.

**DAO NFT ownership and membership**

* `tokenOwner (mapping(uint256 => address))`  
   Tracks the owner of each DAO NFT.  
* `holderBalance (mapping(address => uint256))`  
   Tracks how many DAO NFTs each address currently owns.  
* `holderExists (mapping(address => bool))`  
   Tracks whether an address has ever been registered as a holder.  
* `holders (address[])`  
   Registry of all addresses that have ever held DAO NFTs.

**Dispute tracking**

* `commissionHasActiveDispute (mapping(address => bool))`  
   Prevents multiple simultaneous active disputes for the same commission contract.  
* `disputes (mapping(uint256 => DisputeCase))`  
   Stores all dispute cases by dispute ID.

**Auction tracking**

Each DAO NFT auction is represented by:

**`Auction` struct**

* `tokenId (uint256)`  
   The DAO NFT being auctioned.  
* `startTime (uint256)`  
   Timestamp when the auction starts.  
* `endTime (uint256)`  
   Timestamp when the auction ends.  
* `highestBid (uint256)`  
   Current highest bid in wei.  
* `highestBidder (address)`  
   Current highest bidder.  
* `settled (bool)`  
   Whether the auction has been settled.  
* `auctions (mapping(uint256 => Auction))`  
   Stores auctions by token ID.

**Dispute voting data**

**`VoteOption` enum**

Possible dispute vote outcomes:

* `None`  
* `Artist`  
* `Buyer`  
* `Neither`

**`DisputeCase` struct**

* `commission (address)`  
   The `ArtCommission` contract associated with the dispute.  
* `panelSelected (bool)`  
   Whether jurors have been selected.  
* `resolved (bool)`  
   Whether the dispute has already been resolved.  
* `panelSize (uint256)`  
   Number of jurors to be selected.  
* `votingStart (uint256)`  
   Timestamp when dispute voting starts.  
* `votingEnd (uint256)`  
   Timestamp when dispute voting ends.  
* `totalJurorVotingPower (uint256)`  
   Sum of the DAO NFT balances of all selected jurors at selection time.  
* `jurors (address[])`  
   The selected juror addresses.  
* `artistVotes (uint256)`  
   Total voting power cast in favor of the artist.  
* `buyerVotes (uint256)`  
   Total voting power cast in favor of the buyer.  
* `neitherVotes (uint256)`  
   Total voting power cast in favor of neither party.  
* `usedVotingPower (mapping(address => uint256))`  
   Tracks whether a juror has voted and how much voting power they used.  
* `voteOf (mapping(address => VoteOption))`  
   Records each juror’s chosen vote option. 

**Treasury proposal data**

**`Proposal` struct**

* `creator (address)`  
   The DAO member who created the proposal.  
* `recipient (address)`  
   The address that would receive ETH if the proposal passes.  
* `amount (uint256)`  
   Amount of ETH requested from the treasury.  
* `startTime (uint256)`  
   Timestamp when proposal voting begins.  
* `endTime (uint256)`  
   Timestamp when proposal voting ends.  
* `forVotes (uint256)`  
   Total NFT-weighted voting power in support of the proposal.  
* `againstVotes (uint256)`  
   Total NFT-weighted voting power against the proposal.  
* `executed (bool)`  
   Whether the proposal has been executed.  
* `totalVotingPower (uint256)`  
   Snapshot-like total supply value recorded at proposal creation.  
* `usedVotingPower (mapping(address => uint256))`  
   Tracks whether a voter has already voted and how much power they used.  
* `proposals (mapping(uint256 => Proposal))`  
   Stores all treasury proposals by proposal ID.