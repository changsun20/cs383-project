# The ArtDAO

The ArtCommission and ArtDAO contracts together form an on-chain commission platform where artists and clients can agree on terms, fund escrow, submit work, and complete exchanges of NFTs and payments. A commission progresses through a defined workflow with mutual confirmations, funding deposits, artwork submission, and final asset distribution. Either party may raise a dispute after a deadline passes, at which point the ArtDAO contract selects a jury of DAO NFT holders to vote on the outcome. The DAO also manages treasury proposals and auctions for membership NFTs, using token-weighted voting throughout.

The repository includes two core Solidity contracts alongside supporting test files. The contracts implement the full lifecycle of a commission and the governance mechanics of the DAO, including dispute arbitration, jury selection, and treasury voting.

### Project structure

- `contracts/art_commission.sol` – manages the escrow, state transitions, and resolution of a single art commission
- `contracts/art_dao.sol` – governs DAO membership, dispute jury selection, voting, and treasury proposals
- `contracts/test/ERC721Mock.sol` – a mock ERC-721 implementation used for testing NFT transfers
- `test/artCommissionFlow.js` – tests the basic full happy path and edge cases of a commission
- `test/daoDisputeFlow.js` – tests dispute creation, jury voting, and DAO resolution logic
- `hardhat.config.js` – Hardhat configuration file
- `.github/workflows/compile-and-test.yaml` – CI workflow for compiling and running tests
- `docs/` – VitePress documentation source files

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

### Setup and running 

To compile and run the test suite locally, install dependencies and execute the Hardhat tests:

```sh
npm install
npx hardhat compile
npx hardhat test
```

### Documentation

A comprehensive documentation site is available, built with VitePress and automatically deployed to GitHub Pages.

**Online documentation:** [https://changsun20.github.io/cs383-project/](https://changsun20.github.io/cs383-project/)

**Local development:**
```sh
# Install dependencies (includes vitepress)
npm install

# Preview documentation locally
npx vitepress dev docs

# Build documentation
npx vitepress build docs
```

### Known limitations

The current implementation contains several known limitations that may affect production readiness:

- Fund() Race Condition: If both artist and buyer call fund() in the same block, the contract may remain stuck in the Confirmed state, requiring a goodFaithRelease() to recover assets.
- False DAO Address Injection: The contract deployer can supply an arbitrary DAO address; the confirming party must verify that the legitimate DAO address was used.
- Constant Juror Reward: Jurors receive a fixed reward from the DAO treasury regardless of dispute size, which may lead to treasury depletion over repeated small disputes.
- Dynamic Voting Power After Juror Selection: Juror voting power is calculated from current DAO NFT holdings at vote time, not at selection time, allowing jurors to transfer tokens to alter their influence.

For a complete and detailed description of all invariants, workflows, and known issues, please refer to the full specification documentation.
