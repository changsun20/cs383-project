const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("ArtCommission Normal Flow", () => {
  let artDAO, nft, commission;
  let buyer, artist, deployer;
  
  const price = ethers.parseEther("1.0");
  const upfront = ethers.parseEther("0.3");
  const insurance = ethers.parseEther("0.02");
  const timeframe = 30;

  before(async () => {
    [deployer, buyer, artist] = await ethers.getSigners();
    
    const ArtDAO = await ethers.getContractFactory("ArtDAO");
    artDAO = await ArtDAO.deploy();
    
    const ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    nft = await ERC721Mock.deploy("Test Art", "ART");
    
    await nft.mint(artist.address, 1);
  });

  it("should complete full transaction flow", async () => {
    const ArtCommission = await ethers.getContractFactory("ArtCommission");
    commission = await ArtCommission.connect(buyer).deploy(
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

    const lastPayment = price - upfront;
    await commission.connect(buyer).payInFullAndRelease({
      value: lastPayment
    });

    expect(await nft.ownerOf(1)).to.equal(buyer.address);
    expect(await commission.progress()).to.equal(4);
  });
});