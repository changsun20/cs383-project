//To deploy the TestNFT contract
async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const walletTwo = new ethers.Wallet("0x" + process.env.PRIVATE_KEY_2, provider)
  const MyNFT = await ethers.getContractFactory("MyTestNFT", walletTwo)

  // Start deployment, returning a promise that resolves to a contract object
  const myNFT = await MyNFT.deploy()
  //await myNFT.deployed()
  console.log("Contract deployed to address:", myNFT.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })