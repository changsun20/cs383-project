
const { ethers } = require("hardhat");
require("dotenv").config({path: '../.env'});
 
const CommissionArtifact = require("../artifacts/contracts/art_commission.sol/ArtCommission.json");
const CommissionABI = CommissionArtifact.abi;
const CommissionBytecode = CommissionArtifact.bytecode;
//TODO: comment out before push
const CONTRACT_ADDRESS = "0x54883d111D83d4748af7130B45718eE79319Cb12"
const NFT_CONTRACT_ADDRESS = "0x08a9003402b80001282f192baec5cd16a7fbc834"


async function main() {
    //const [buyer, artist] = await ethers.getSigners();
    const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
    //buyer
    const wallet = new ethers.Wallet("0x" + process.env.PRIVATE_KEY, provider)
    //artist
    const walletTwo = new ethers.Wallet("0x" + process.env.PRIVATE_KEY_2, provider)

    //

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

    /*
    //TODO: fill back in
    const factory = new ethers.ContractFactory(CommissionABI, CommissionBytecode,  wallet)
    //deploy with buyer, artist, insurance, price, upfrontpayment, timeframe, address of dao
    //432000 = 5 days in seconds
    const contract = await factory.deploy(wallet.address, walletTwo.address, insurance, price, upfrontPayment, 432000 ,"0x0000000000000000000000000000000000000000" )
    //create a connection from the artist account to the contract
    
    */
    const contract = await ethers.getContractAt("ArtCommission", CONTRACT_ADDRESS, wallet  )
    //const contractAsArtist = contract.connect(walletTwo)
    const contractAsArtist = await ethers.getContractAt("ArtCommission", CONTRACT_ADDRESS, walletTwo)
    console.log("connected")
    console.log(contract.target)
    console.log(Object.keys(contract))

    //TODO fill back in 
    //artist action - approve the contract
    /*const responseOne = await contractAsArtist.contractConfirm()
    console.log(responseOne)

    //Buyer action- fund the contract
    const responseTwo = await contract.fund({value: buyerValueToSend})
    console.log(responseTwo)
    await responseTwo.wait()

    //artist action - fund the contract
    const responseThree = await contractAsArtist.fund({value: artistValueToSend})
    console.log(responseThree)*/

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
    const nftAddress = String(receipt.logs[1].address)
    console.log("Minted NFT " + tokenID.toString() + " address " + nftAddress)

    /*//wait for artificial timeout
    setTimeout(() => {
        console.log("Waited 30 seconds!");
    }, 30000);
    await new Promise(r => setTimeout(r, 30000));*/
    console.log("caller:", await walletTwo.getAddress());
    console.log("artist:", await contractAsArtist.artist());
    console.log("progress:", await contractAsArtist.progress());
    console.log("tokenID:", tokenID.toString());
    console.log("owner:", await myNFT.ownerOf(tokenID));

    //artist action - submit nft
    //const responseFive = await contractAsArtist.acceptArt(nftAddress, tokenID)
    const responseFive = await contractAsArtist.callStatic.acceptArt(nftAddress, tokenID);
    console.log(responseFive)

    //buyer action - send last payment, recieve nft, resolve transaction
    const responseSix = await contract.payInFullAndRelease({value: buyerValueToSendLast})
    console.log(responseSix)
}

main().catch(console.error);