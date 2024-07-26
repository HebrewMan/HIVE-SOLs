import { ethers } from "hardhat";
async function main() {
    const [nacOwner, nacVault, addr3 ] = await ethers.getSigners();
    
    const claimAddr = "0x49D9EA042bAd845c2552554e1Fd7D22deb76F5D5"; 
  
    const ClaimRewards = await ethers.getContractAt("ClaimRewards", claimAddr,nacOwner);

    const data = {
        token:'0x55d398326f99059fF775485246999027B3197955',
        claimAmount:'1458028224000000000000',
        burnAmount:'0',
        endTime:10000000000,
        nonce:0,
        sign:''
    }

    const {token,claimAmount,burnAmount,endTime,nonce,sign} = data;

    const tx = await ClaimRewards.claim(token,claimAmount,burnAmount,endTime,nonce,sign)

    console.log(tx.hash);

    await tx.wait();

    console.log("successful~~ ");
    

    //ICO 3

    // const ICO3 = await ethers.deployContract("ICO3");
    // await ICO3.waitForDeployment();
    
    // await NAC.setWhiteStatus(ICO3.target,true);

    // await NAC.connect(nacVault).approve(ICO3.target,'100000000000000000000000000')

    // console.log('============ICO3 address ============')
    // console.log(ICO3.target)

 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

