
const { ethers } = require("hardhat");
require("dotenv").config({path: '../.env'});
 
const CommissionArtifact = require("../artifacts/contracts/art_commission.sol/ArtCommission.json");
const CommissionABI = CommissionArtifact.abi;
const CommissionBytecode = CommissionArtifact.bytecode;
//const CONTRACT_ADDRESS = ""
const NFT_CONTRACT_ADDRESS = "0x08a9003402b80001282f192baec5cd16a7fbc834"


async function main() {
    //const [buyer, artist] = await ethers.getSigners();
    const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
    //buyer
    const wallet = new ethers.Wallet("0x" + process.env.PRIVATE_KEY, provider)
    //artist
    const walletTwo = new ethers.Wallet("0x" + process.env.PRIVATE_KEY_2, provider)
    const factory = new ethers.ContractFactory(CommissionABI, CommissionBytecode,  wallet)

    const insurance = ethers.parseUnits("7500000000000000", "wei")
    const price = ethers.parseUnits("2000000000000000", "wei")
    //send half of payment upfront
    const upfrontPayment = ethers.parseUnits("1000000000000000", "wei")
    //insurance and upfront payment
    const buyerValueToSend = ethers.parseUnits("4750000000000000", "wei")
    //send this to complete the transaction
    const buyerValueToSendLast = ethers.parseUnits("1000000000000000", "wei")
    //value is half of insurance
    const artistValueToSend = ethers.parseUnits("3750000000000000", "wei")

    //deploy with buyer, artist, insurance, price, upfrontpayment, timeframe, address of dao
    //432000 = 5 days in seconds
    const contract = await factory.deploy(wallet.address, walletTwo.address, insurance, price, upfrontPayment, 432000 ,"0x0000000000000000000000000000000000000000" )
    //create a connection from the artist account to the contract
    const contractAsArtist = contract.connect(walletTwo)

    //artist action - approve the contract
    const responseOne = await contractAsArtist.contractConfirm()
    console.log(responseOne)

    //Buyer action- fund the contract
    const responseTwo = await contract.fund({value: buyerValueToSend})
    console.log(responseTwo)

    //artist action - fund the contract
    const responseThree = await contractAsArtist.fund({value: artistValueToSend})
    console.log(responseThree)

    //TODO - not sure of this logic
    //create an nft - use MyTestNFT.sol
    //https://stackoverflow.com/questions/72356857/how-to-receive-a-value-returned-by-a-solidity-smart-contract-transacting-functio
    const myNFT = await ethers.getContractAt("MyTestNFT", NFT_CONTRACT_ADDRESS)
    const myNFTWithArtist = myNFT.connect(walletTwo);
    const recipient = walletTwo.address;
    
    const tokenURI = "https://github.com/alison-at/dummy_metadata_cs_383/blob/main/testdata.json"
    const responseFour = await myNFTWithArtist.mintNFT(recipient, tokenURI);
    const receipt = await responseFour.wait();
    //console.log(JSON.stringify(receipt, null, 2));
    const tokenID = BigInt(receipt.logs[1].data);
    console.log("Minted NFT " + tokenID.toString())

    //wait for artificial timeout
        setTimeout(() => {
        console.log("Waited 3 seconds!");
    }, 30000);

    //artist action - submit nft
    const responseFive = await contractAsArtist.acceptArt(nftAddress, tokenID)
    console.log(responseFive)

    //buyer action - send last payment, recieve nft, resolve transaction
    const responseSix = await contract.payInFullAndRelease({value: buyerValueToSendLast})
    console.log(responseSix)
}

main().catch(console.error);