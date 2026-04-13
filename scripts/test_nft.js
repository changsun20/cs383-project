
const { ethers } = require("hardhat");
require("dotenv").config({path: '../.env'});

const NFT_CONTRACT_ADDRESS = "0x08a9003402b80001282f192baec5cd16a7fbc834"


async function main() {
   
    const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
    const walletTwo = new ethers.Wallet("0x" + process.env.PRIVATE_KEY_2, provider)



    //TODO - not sure of this logic
    //create an nft - use MyTestNFT.sol
    //https://stackoverflow.com/questions/72356857/how-to-receive-a-value-returned-by-a-solidity-smart-contract-transacting-functio
    const myNFT = await ethers.getContractAt("MyTestNFT", NFT_CONTRACT_ADDRESS)
    const myNFTWithArtist = myNFT.connect(walletTwo);
    console.log("connected")
    const recipient = walletTwo.address;

    const tokenURI = "https://github.com/alison-at/dummy_metadata_cs_383/blob/main/testdata.json"
    const responseFour = await myNFTWithArtist.mintNFT(recipient, tokenURI);
    const receipt = await responseFour.wait();
    //console.log("got receipt:", receipt);
    console.log(JSON.stringify(receipt, null, 2));
    //console.dir(receipt, { depth: null });
    const value = BigInt(receipt.logs[1].data);
    const nftAddress = String(receipt.logs[1].address)
    console.log("Minted NFT " + value.toString() + " address " + nftAddress)
    /*
    const [transferEvent] = receipt.logs;
    const { tokenId } = transferEvent.args;
    console.log("MintedNFT " + tokenID)*/

  
}

main().catch(console.error);