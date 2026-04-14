# ArtDAO (art_dao.sol)

## Purpose: 

The `ArtDAO` contract governs membership, dispute arbitration, and collective treasury decision-making within the art commission ecosystem. DAO membership is represented by DAO NFTs, which are distributed through periodic auctions and give holders both governance rights and participation in the dispute-resolution process. When a commission dispute arises, the DAO selects a jury from eligible token holders, with each holder’s likelihood of selection weighted by the number of DAO NFTs they own. Selected jurors are compensated for their participation using funds derived from the insurance escrow associated with disputed commission contracts. In addition to dispute arbitration, the DAO also enables members to collectively vote on treasury proposals.

The DAO has two main responsibilities:

1. **Dispute Resolution for Art Commissions**  
    When an `ArtCommission` contract enters dispute, the DAO creates a dispute case, selects a weighted jury from eligible DAO members, collects juror votes, and then resolves the dispute by calling the appropriate function on the commission contract.  
2. **Treasury Governance Through Proposals**  
    DAO members may create proposals requesting that ETH from the DAO treasury be transferred to a recipient. DAO members vote with power proportional to the number of DAO NFTs they hold. If a proposal reaches the required supermajority threshold, it may be executed and the transfer is made.

## DAO workflow:

The general DAO workflow is as follows:

**DAO Membership / NFT Workflow**

1. The DAO periodically mints a new DAO NFT into its treasury.  
2. The DAO immediately starts an auction for that NFT.  
3. Participants bid in ETH during the auction period.  
4. After the auction ends, the highest bidder receives the DAO NFT.  
5. DAO NFT ownership determines DAO membership, voting power, and jury-selection weight.

**Dispute Resolution Workflow**

1. A dispute is created through an `ArtCommission` contract.  
2. The DAO records the dispute case and associates it with that commission.  
3. A panel of jurors is selected from eligible DAO NFT holders using weighted lottery.  
4. Each selected juror votes for one of three outcomes:  
   * in favor of the artist  
   * in favor of the buyer  
   * in favor of neither  
5. Once voting ends, or all jurors have voted, the DAO resolves the dispute.  
6. The DAO calls the corresponding dispute-resolution function on the `ArtCommission` contract.  
7. Jurors who participated in voting receive a fixed jury reward.

**Treasury Proposal Workflow**

1. Any DAO member holding at least one DAO NFT may create a proposal.  
2. The proposal specifies a recipient and an amount of ETH from the DAO treasury.  
3. DAO members vote for or against the proposal using NFT-weighted voting power.  
4. After the voting period ends, the proposal may be executed if it has enough support.  
5. If executed, the requested ETH is transferred from the DAO treasury to the proposal recipient.