
const { ethers } = require("hardhat");
 
const CommissionArtifact = require("../artifacts/contracts/art_commission.sol/art_commission.json");
const CommissionABI = CommissionArtifact.Abi;
const commissionBytecode = CommissionArtifact.bytecode;
const CONTRACT_ADDRESS = ""


async function main() {
    const provider = new ethers.JsonRpcProvider(env.SEPOLIA_RPC_URL);
    
    const wallet = new ethers.Wallet("0x" + env.PRIVATE_KEY, provider);
    
    const factory = new ethers.ContractFactory( CommissionAbi, CommissionBytecode,  wallet)

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
    const contract = factory.deploy(env.MY_ADDRESS, "", insurance, price, upfrontPayment, 432000 ,"" )

    //artist action - approve the contract
    //TODO - major issue with test - how do I send transactions as if from artist?

    //Buyer action- fund the contract
    const responseTwo = await contract.fund({value: buyerValueToSend})

    //artist action - fund the contract

    //create an nft
    //artist action - submit nft

    //buyer action - send last payment, recieve nft, resolve transaction
    const responseSix = await contract.payInFullAndRelease({value: buyerValueToSendLast})

}

main().catch(console.error);