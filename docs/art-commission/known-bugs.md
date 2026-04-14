# Known Bugs

**Known Bugs:**

**Fund() Race Condition:**   
It is theoretically possible to have an artist and a buyer call fund() in the same block of transactions, so that both fund their part of the contract but for neither of them does progress get set to Funded. At each transaction, the state is such that the other party is not shown to have submitted funds. The contract would get stuck in a Confirmed state with no way to move forward. The parties would have to goodFaithRelease(), because dispute() cannot be called with state Confirmed.

**False DAO Address Injection:**  
It is possible to pass an address which is not the DAO to the DAO address parameter in the ArtCommission constructor. The confirming party will have to insure that the contract creator passed in the legitimate DAO address.