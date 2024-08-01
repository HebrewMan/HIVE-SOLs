import { ethers } from "hardhat";

async function main() {
    const [nacOwner, addr2,addr3 ] = await ethers.getSigners();

    // const NACNFT = await ethers.deployContract("NACNFT");
    // await NACNFT.waitForDeployment();

    // console.log('============ NFT address ============')
    // console.log(NACNFT.target)
    console.log('========================')
    console.log(nacOwner.address)
    console.log(addr2.address)
    console.log(addr3.address)

 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

