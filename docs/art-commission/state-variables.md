# State Variables

**State variables:**   
**Price details**

* **fullPrice** (uint256): the full price of the commission agreed upon by both artist and buyer.  
* **upfrontPayment** (uint256): the portion of the total commission price that the buyer deposits into the contract as an initial payment to guarantee commitment from both parties.  
* **lastPayment** (uint256): the portion of the total commission price that the buyer pays during the final exchange of digital assets between artist and buyer; an artist and buyer may agree not to include a final payment in their commission.  
* **insurance** (uint256): the total amount deposited by both parties into the contract as escrowed insurance; in the event of a dispute, the portion contributed by the dispute calling party is transferred to the DAO as a fee for dispute resolution.

**NFT artwork details**

* **artwork** (IERC721): a reference to the artwork’s ERC-721 contract  
* **artID** (uint256): the tokenID of the artwork NFT within the contract

**Involved parties**

* **artist** (address): the address of the commission artist  
* **buyer** (address): the address of the commission buyer  
* **DAO** (address): the address of the DAO who would vote on a resolution if a dispute is raised

**Decision variables**

* **artistInitiated** (bool): whether the artist was the party initiating the commission contract  
* **buyerBreakFaith** (bool): the buyer’s decision to cancel the commission  
* **artistBreakFaith** (bool): the artist’s decision to cancel the commission

**Commission timeline variables**

* **timeInitiated** (uint): the time the commission began  
* **numberOfDaysToCompletion** (uint): the deadline for the artist to complete the artwork  
* **progress** (State): the current state of a commission in the workflow