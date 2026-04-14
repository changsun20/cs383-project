# Known Bugs

## Known Bugs

**Constant Juror Reward:**  
Juror rewards are defined as a fixed constant (`JURY_REWARD`) and are paid from the DAO treasury, regardless of the size or outcome of the dispute.  
The DAO may pay out more in juror rewards than it receives from dispute-related insurance funds, especially in small disputes or repeated cases. Over time, this creates a misaligned incentive structure and may lead to gradual depletion of DAO funds.

### **Dynamic Voting Power After Juror Selection**

A juror’s voting power during `vote()` is determined by their current `holderBalance`, rather than a snapshot taken at the time of juror selection.

Jurors can transfer DAO NFTs before voting to increase or decrease their voting power, leading to inconsistencies between the intended weighted selection and the actual voting influence. This creates a **time-of-check vs. time-of-use inconsistency** in governance.