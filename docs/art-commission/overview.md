# ArtCommission (art_commission.sol)

**Purpose:** The ArtCommission contract facilitates NFT-based art commissions between clients and artists. This contract manages the full commission workflow, including commission proposal, funding, artwork submission, and the final digital asset exchange with several approval requirements throughout the process.

**The general workflow of a commission is as follows:**

1. Contract construction (proposal of initial terms)  
2. Confirmation by the non-initiating party  
3. Funding by both parties  
4. Submission of artwork by the artist  
5. One of two outcomes:  
   (1) Successful completion, where assets are exchanged according to the agreement  
   (2) Dispute, where a party raises a claim after the agreed work completion deadline passes and the DAO determines asset distribution

At any point prior to reaching the Completed commission state, the parties may mutually agree to cancel the commission via goodFaithRelease(), in which case any assets in escrow are redistributed accordingly.

**Invariants:**

* Artist and buyer addresses are the only valid contract participants and are immutable  
* Only the DAO address may execute dispute resolution functions  
* The total commission price must equal the upfrontPayment \+ lastPayment  
* The contract holds the artwork NFT in escrow if and only if the commission is in the WorkCompleted state or during an unresolved dispute state  
* The commission state (progress) follows valid transitions and cannot skip stages in the workflow  
* All funds (payments and insurance) are distributed only according to the defined outcomes: completion, mutual cancellation, or DAO-mediated dispute resolution

**Example ArtCommission Contract:**  
Sepolia Ethernet Contract 0x7F6e9e6668a052Ff145135929396E3D9F43D00bC ([https://sepolia.etherscan.io/address/0x7F6e9e6668a052Ff145135929396E3D9F43D00bC](https://sepolia.etherscan.io/address/0x7F6e9e6668a052Ff145135929396E3D9F43D00bC))