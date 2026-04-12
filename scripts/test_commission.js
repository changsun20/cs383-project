
const { ethers } = require("hardhat");
 
const CommissionArtifact = require("../artifacts/contracts/art_commission.sol/art_commission.json");
const CommissionABI = CommissionArtifact.Abi;
const commissionBytecode = CommissionArtifact.bytecode;
const CONTRACT_ADDRESS = ""

async function main() {
    const provider = new ethers.JsonRpcProvider(env.SEPOLIA_RPC_URL);
    
    const wallet = new ethers.Wallet("0x" + env.PRIVATE_KEY, provider);
    
    const factory = new ethers.ContractFactory( CommissionAbi, CommissionBytecode,  wallet)

    const insurance = ethers.parseUnits("", "wei")
    const upfrontPayment = ethers.parseUnits("", "wei")
    const valueToSend = ethers.parseUnits("", "wei")
    //deploy with buyer, artist, insurance, price, upfrompayment, timeframe, address of dao
    const contract = factory.deploy("", "", )
}

main().catch(console.error);