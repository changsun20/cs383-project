# Functions

## Functions

**Constructor()**

**Purpose:**  
 Initializes the DAO contract, sets the starting values for token, dispute, and proposal IDs, and registers the DAO treasury contract itself as a holder record.

## DAO NFT / Auction Functions

**mint()**

**Purpose:**  
Mints a new DAO NFT into the DAO treasury if the required mint interval has passed, then immediately starts an auction for that NFT.

**\_startAuction()**

**Purpose:**  
Internal helper that initializes auction data for a newly minted treasury-held DAO NFT.

**bid()**

**Purpose:**  
Allows a user to place a bid in ETH on an active DAO NFT auction. If a previous highest bidder exists, that bidder is refunded immediately.

**settleAuction()**

**Purpose:**  
Finalizes an auction after its end time. If a highest bidder exists, the DAO NFT is transferred from the treasury to that bidder.

**transfer()**

**Purpose:**  
Allows the current owner of a DAO NFT to transfer it to another address.

**balanceOf()**

**Purpose:**  
Returns the number of DAO NFTs currently held by an address.

**ownerOf()**

**Purpose:**  
Returns the current owner of a specific DAO NFT.

**treasuryBalance()**

**Purpose:**  
Returns the amount of ETH currently held by the DAO treasury.

## Dispute Resolution Functions

**createDisputeCase()**

**Purpose:**  
 Creates a new dispute case tied to a specific `ArtCommission` contract. This prevents the same commission from opening multiple simultaneous active disputes.

**selectJurors()**

**Purpose:**  
 Selects a panel of jurors for a dispute using a weighted lottery. DAO members with more DAO NFTs have greater weight and therefore a higher probability of selection.

**Eligibility rules:**  
 A juror candidate must:

* own at least one DAO NFT,  
* not be the DAO treasury,  
* not be the artist in the associated commission,  
* not be the buyer in the associated commission.

Selected jurors are unique and cannot appear more than once in the same panel.

**vote()**

**Purpose:**  
 Allows a selected juror to cast a single NFT-weighted vote on a dispute in favor of:

* the artist,  
* the buyer, or  
* neither party.

**resolveDispute()**

**Purpose:**  
 Finalizes a dispute after voting has ended, or after all jurors have voted. The DAO determines the winning outcome and calls the corresponding resolution function on the linked `ArtCommission` contract.

After resolution, jurors who voted receive the fixed `JURY_REWARD`.

## Proposal Governance Functions

**createProposal()**

**Purpose:**  
 Allows a DAO member holding at least one DAO NFT to create a treasury proposal requesting an ETH transfer from the DAO treasury to a specified recipient.

**voteProposal()**

**Purpose:**  
 Allows DAO members to vote for or against a treasury proposal with voting power proportional to the number of DAO NFTs they currently hold.

**executeProposal()**

**Purpose:**  
 Executes a proposal after the voting period has ended if the proposal has enough support. If execution succeeds, the specified ETH amount is transferred from the DAO treasury to the proposal recipient.

The current implementation requires at least **67% of total recorded voting power** to support the proposal.

**getProposal()**

**Purpose:**  
 Returns the public information for a proposal, including creator, recipient, amount, voting totals, execution status, and total voting power recorded for the proposal.

## View / Helper Functions

**getJurors()**

**Purpose:**  
Returns the list of jurors selected for a given dispute.

**getVoteCounts()**

**Purpose:**  
Returns the current weighted vote totals for artist, buyer, and neither in a given dispute.

**getJurorVote()**

**Purpose:**  
Returns whether a particular juror has voted in a dispute and which option they selected.

**getAllHolders()**

**Purpose:**  
Returns the registry of all addresses that have ever held a DAO NFT.

## Internal Functions

**\_addHolderIfNeeded()**

**Purpose:**  
Registers an address in the historical holder list if it has not been seen before.

**\_moveToken()**

**Purpose:**  
Internal helper used for minting and transferring DAO NFTs while keeping `tokenOwner` and `holderBalance` synchronized.

**\_getEligibleCandidates()**

**Purpose:**  
Builds the list of eligible juror candidates and their selection weights for a dispute.

**\_isJuror()**

**Purpose:**  
Checks whether a given address is one of the selected jurors for a dispute.

**\_allJurorsVoted()**

**Purpose:**  
Returns true if every selected juror has already cast a vote.

**\_calculateOutcome()**

**Purpose:**  
Determines the final dispute outcome from the weighted vote totals.

Under the current implementation:

* if artist votes exceed 50% of total votes cast, artist wins;  
* if buyer votes exceed 50% of total votes cast, buyer wins;  
* if neither votes exceed 50% of total votes cast, neither wins;  
* otherwise, the result defaults to `Neither`.

**receive()**

**Purpose:**  
Allows the DAO contract to receive ETH directly into its treasury.