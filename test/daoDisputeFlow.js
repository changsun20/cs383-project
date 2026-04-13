const { ethers, network } = require("hardhat");
const { expect } = require("chai");

describe("DAO Dispute Resolution Flow", () => {
    let buyer, artist, holder1, holder2, holder3, holder4;

    const price = ethers.parseEther("1.0");
    const upfront = ethers.parseEther("0.3");
    const insurance = ethers.parseEther("0.02");
    const timeframe = 1;
    const panelSize = 3;
    const votingDuration = 300;
    const VoteOption = { None: 0, Artist: 1, Buyer: 2, Neither: 3 };

    before(async () => {
        [, buyer, artist, holder1, holder2, holder3, holder4] =
            await ethers.getSigners();
    });

    async function setupNewDAO() {
        const ArtDAO = await ethers.getContractFactory("ArtDAO");
        const artDAO = await ArtDAO.deploy();

        await network.provider.send("evm_increaseTime", [7 * 86400]);
        await network.provider.send("evm_mine");
        await artDAO.mint();

        await artDAO
            .connect(holder1)
            .bid(1, { value: ethers.parseEther("0.01") });
        await network.provider.send("evm_increaseTime", [7 * 86400 + 1]);
        await network.provider.send("evm_mine");
        await artDAO.settleAuction(1);

        await network.provider.send("evm_increaseTime", [7 * 86400]);
        await network.provider.send("evm_mine");
        await artDAO.mint();

        await artDAO
            .connect(holder2)
            .bid(2, { value: ethers.parseEther("0.02") });
        await artDAO
            .connect(holder3)
            .bid(2, { value: ethers.parseEther("0.03") });
        await network.provider.send("evm_increaseTime", [7 * 86400 + 1]);
        await network.provider.send("evm_mine");
        await artDAO.settleAuction(2);

        await network.provider.send("evm_increaseTime", [7 * 86400]);
        await network.provider.send("evm_mine");
        await artDAO.mint();

        await artDAO
            .connect(holder4)
            .bid(3, { value: ethers.parseEther("0.01") });
        await network.provider.send("evm_increaseTime", [7 * 86400 + 1]);
        await network.provider.send("evm_mine");
        await artDAO.settleAuction(3);

        return artDAO;
    }

    async function createDisputeScenario(artDAO, voteChoice) {
        const ERC721Mock = await ethers.getContractFactory("ERC721Mock");
        const nft = await ERC721Mock.deploy("Test Art", "ART");
        await nft.mint(artist.address, 1);

        const ArtCommission = await ethers.getContractFactory("ArtCommission");
        const commission = await ArtCommission.connect(buyer).deploy(
            buyer.address,
            artist.address,
            insurance,
            price,
            upfront,
            timeframe,
            artDAO.target
        );

        await commission.connect(artist).contractConfirm();

        const artistFund = insurance / 2n;
        const buyerFund = insurance / 2n + upfront;

        await commission.connect(artist).fund({ value: artistFund });
        await commission.connect(buyer).fund({ value: buyerFund });

        await nft.connect(artist).approve(commission.target, 1);
        await commission.connect(artist).acceptArt(nft.target, 1);

        await network.provider.send("evm_increaseTime", [2 * 86400]);
        await network.provider.send("evm_mine");

        await commission.connect(buyer).raiseDispute(panelSize, votingDuration);

        const disputeId = await commission.disputeId();
        await artDAO.selectJurors(disputeId, votingDuration);

        const jurors = await artDAO.getJurors(disputeId);

        for (const jurorAddr of jurors) {
            const juror = await ethers.getSigner(jurorAddr);
            await artDAO.connect(juror).vote(disputeId, voteChoice);
        }

        await network.provider.send("evm_increaseTime", [votingDuration + 1]);
        await network.provider.send("evm_mine");

        await artDAO.resolveDispute(disputeId);

        return { commission, nft, disputeId };
    }

    it("Artist win", async () => {
        const artDAO = await setupNewDAO();
        const { commission, nft } = await createDisputeScenario(
            artDAO,
            VoteOption.Artist
        );

        expect(await commission.progress()).to.equal(4);
        expect(await nft.ownerOf(1)).to.equal(artist.address);
    });

    it("Buyer win", async () => {
        const artDAO = await setupNewDAO();
        const { commission, nft } = await createDisputeScenario(
            artDAO,
            VoteOption.Buyer
        );

        expect(await commission.progress()).to.equal(4);
        expect(await nft.ownerOf(1)).to.equal(buyer.address);
    });

    it("Neither win", async () => {
        const artDAO = await setupNewDAO();
        const { commission, nft } = await createDisputeScenario(
            artDAO,
            VoteOption.Neither
        );

        expect(await commission.progress()).to.equal(4);
        expect(await nft.ownerOf(1)).to.equal(artist.address);
    });
});
