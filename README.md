# The ArtDAO

The ArtCommission and ArtDAO contracts together form an on-chain commission platform where artists and clients can agree on terms, fund escrow, submit work, and complete exchanges of NFTs and payments. A commission progresses through a defined workflow with mutual confirmations, funding deposits, artwork submission, and final asset distribution. Either party may raise a dispute after a deadline passes, at which point the ArtDAO contract selects a jury of DAO NFT holders to vote on the outcome. The DAO also manages treasury proposals and auctions for membership NFTs, using token-weighted voting throughout.

The repository includes two core Solidity contracts alongside supporting test files. The contracts implement the full lifecycle of a commission and the governance mechanics of the DAO, including dispute arbitration, jury selection, and treasury voting.

Project structure:
- `contracts/art_commission.sol` – manages the escrow, state transitions, and resolution of a single art commission
- `contracts/art_dao.sol` – governs DAO membership, dispute jury selection, voting, and treasury proposals
- `contracts/test/ERC721Mock.sol` – a mock ERC-721 implementation used for testing NFT transfers
- `test/artCommissionFlow.js` – tests the basic full happy path and edge cases of a commission
- `test/daoDisputeFlow.js` – tests dispute creation, jury voting, and DAO resolution logic
- `hardhat.config.js` – Hardhat configuration file
- `.github/workflows/compile-and-test.yaml` – CI workflow for compiling and running tests

```
.
├── contracts
│   ├── art_commission.sol
│   ├── art_dao.sol
│   └── test
│       └── ERC721Mock.sol
├── .github
│   └── workflows
│       └── compile-and-test.yaml
├── .gitignore
├── hardhat.config.js
├── package.json
├── package-lock.json
├── README.md
└── test
    ├── artCommissionFlow.js
    └── daoDisputeFlow.js
```


To run the test suite locally, install dependencies and execute the Hardhat tests:

```sh
npm install
npx hardhat test
```
