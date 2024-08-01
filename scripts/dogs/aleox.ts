import { ethers } from "hardhat";

async function main() {
    const [nacOwner, addr2,addr3 ] = await ethers.getSigners();

    const ALEOX = await ethers.deployContract("ALEOX");
    await ALEOX.waitForDeployment();

    console.log('============ Aleox address ============')
    console.log(ALEOX.target)

 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

