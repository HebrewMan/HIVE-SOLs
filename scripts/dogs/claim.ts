import { ethers } from "hardhat";

async function main() {
    const [nacOwner, addr2,addr3 ] = await ethers.getSigners();

    const ClaimRewards2 = await ethers.deployContract("ClaimRewards2");
    await ClaimRewards2.waitForDeployment();

    console.log('============ ClaimRewards2 address ============')
    console.log(ClaimRewards2.target)

 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

