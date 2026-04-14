# Functions

**Functions:**  
**Constructor():**

* **Purpose:** Initialize an art commission; the contract deployer proposes payment values, a timeframe for work completion, and provides the addresses of the involved parties.  
* **Function:** set initial values of involved parties’, payment variables, numberOfDaysToCompletion, artistInitiated, and set the initial progress state to Proposed.  
* **Condition:** upon ArtCommission contract deployment  
* **Invariant:**  
  * Addresses of involved parties should be immutable after ArtCommission contract deployment.

**onERC721Recieved():**

* **Purpose:** implementation of a function from the OpenZeppelin IERC721Receiver interface to fulfill ArtCommission inheritance.  
* **Function:** enable smart contract to receive NFT via safeTransferFrom, ensuring that the NFT is sent from the commission’s listed artist.  
* **Condition:** utilized when acceptArt() function is called successfully by the artist listed in the ArtCommission contract details. Otherwise the deposit is reverted and the NFT stays under the artist’s ownership.  
* **Invariant:**  
  * If a party that is not listed as the artist in ArtCommission attempts to transfer an NFT to the ArtCommission, the acceptArt() function should revert due to the require in onERC721Recieved.

**contractConfirm():**

* **Purpose:** Facilitates the party who did not initiate the art commission contract to approve the proposed commission details.  
* **Function:** when the party who did not initiate the ArtCommission contract calls this function, the ArtCommission progress state should update to Confirmed and emit the ContractConfirmed event.  
* **Condition:** the commission state should be at Proposed.  
* **Invariant:**  
  * No digital assets should be stored in the contract ArtCommission at this point.  
  * Only the artist and buyer may interact with this function.  
  * If the party who initiated the ArtCommission contract calls this function, the progress state should still be at Proposed.  
  * After the function is called successfully, the ArtCommission progress state should be at Confirmed.

**fund():**

* **Purpose:** Facilitates the artist and buyer to independently deposit half of the insuranceAmount into escrow; the buyer additionally deposits the upfrontPayment.  
* **Function:** Artist and buyer transfer half of the insuranceAmount to the ArtCommission contract. Additionally, the buyer transfers the upfrontPayment amount to the smart contract. Update progress state to Funded. Emit Funded event.  
* **Condition:** ArtCommission progress state should be at Confirmed.  
* **Invariant:**   
  * Only the artist and buyer may interact with this function.  
  * Artwork NFT should not be stored in the contract ArtCommission at this point.  
  * After the function is called successfully, the ArtCommission progress state should be at Funded.

**acceptArt():**

* **Purpose:** Facilitates the artist to deposit the artwork NFT into escrow.  
* **Function:** Transfer the artwork NFT from the artist to the ArtCommission contract. Assign values to artwork NFT detail variables (e.g. artwork and artworkID). Update progress state to WorkCompleted. Emit ArtworkSubmitted event.  
* **Condition:** ArtCommission progress state should be at Funded.  
* **Invariant:**  
  * Only the artist may interact with this function.  
  * After this function is called successfully, the ArtCommission contract should have ownership of the artwork NFT and the progress state should be at WorkCompleted.

**payInFullAndRelease():**

* **Purpose:** Manages distribution of digital assets for a successful commission outcome. The buyer should receive the artwork from the smart contract. The artist receives the upfrontPayment and lastPayment. Both parties also receive their deposited insurance contributions.  
* **Function:** Transfer the artwork NFT from the contract to the buyer. Transfer the upfrontPayment from the contract to the artist. Additionally, transfer the lastPayment from the buyer to artist, and transfer half the insuranceAmount to each party. Update progress state to Completed and emit CompletedSuccessfully event.  
* **Condition:** ArtCommission progress state should be at WorkCompleted.  
* **Invariant:**  
  * Only the buyer may interact with this function.  
  * After this function is called successfully, progress state should be at Completed and digital assets should be distributed as described in the functionality.

**goodFaithRelease():**

* **Purpose:** Manages distribution of digital assets for a mutually approved commission cancellation.  
* **Function:**  
  * If funds in escrow, but not the artwork: transfer upfrontPayment and half of the insuranceAmount to buyer, as well as half the insuranceAmount to the artist.  
  * If funds and the artwork in escrow: transfer half the insuranceAmount to each party, and additionally transfer the artwork NFT and upfrontPayment to the artist.  
  * Update progress state to completed and emit GoodFaithCancelled event.  
* **Condition:** Can be called at any point after the ArtCommission contract has been deployed, but only successfully enacts it’s full functionality when both artistBreakFaith and buyerBreakFaith are true.  
* **Invariant:**  
  * Only artist and buyer can interact with this function.  
  * The distribution of digital assets as described in this function’s functionality should not be carried out if artistBreakFaith and buyerBreakFaith are not both true.  
  * After this function is successfully called, progress state should be Completed and digital assets should be distributed as described in the functionality.

**raiseDispute():**

* **Purpose:** After the numberOfDaysToCompletion deadline has passed, this function allows either the buyer or artist to raise a dispute case to the art DAO.  
* **Function:** Provide the number of jurors for the DAO to select to handle the dispute case and the voting duration in the DAO. Create a dispute case for the ArtCommission to be resolved by the DAO. Update progress state to Disputed and emit DisputeRaised event.  
* **Condition:** Progress state must be at Funded or WorkCompleted. Can only be called by an involved party after numberOfDaysToCompletion have been passed since the timeInitiated.  
* **Invariant:**  
  * Only the artist and buyer can interact with this function.

**artistWins():**

* **Purpose:** Manages distribution of digital assets when the DAO resolves the dispute in favor of the artist.  
* **Function:** Transfer artwork NFT and half insuranceAmount to artist. Transfer buyer’s half of insuranceAmount to DAO.  
* **Condition:** Progress state should be at Disputed.  
* **Invariant:**  
  * Only the DAO can interact with this function.  
  * After this function is successfully called, progress state should be at Completed and digital assets should be distributed as described in the functionality.

**buyerWins():**

* **Purpose:** Manages distribution of digital assets when the DAO resolves the dispute in favor of the buyer.  
* **Function:** Transfer artwork NFT and half insuranceAmount to buyer. Transfer artist’s half of insuranceAmount to DAO.  
* **Condition:** Progress state should be at Disputed.  
* **Invariant:**  
  * Only the DAO can interact with this function.  
  * After this function is successfully called, progress state should be at Completed and digital assets should be distributed as described in the functionality.

**neitherWins():**

* **Purpose:** Manages distribution of digital assets when the DAO resolves the dispute in favor of neither party.  
* **Function:**  
  * If artwork NFT is in escrow, transfer to artist.  
  * If payments \+ insuranceAmount in escrow, transfer payments to buyer and insuranceAmount in full to the DAO.  
  * If no payments in escrow besides insuranceAmount, only transfer insuranceAmount in full to the DAO.  
* **Condition:** Progress state should be at Disputed.  
* **Invariant:**  
  * Only the DAO can interact with this function.  
  * After this function is successfully called, progress state should be at Completed and digital assets should be distributed as described in the functionality.