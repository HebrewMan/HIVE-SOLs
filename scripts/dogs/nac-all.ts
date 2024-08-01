import { ethers } from "hardhat";
async function main() {
    const [nacOwner, nacVault, addr3 ] = await ethers.getSigners();

    const usdtAddress = '0x55d398326f99059fF775485246999027B3197955';
    
    const NAC = await ethers.deployContract("NAC");
    await NAC.waitForDeployment();

    const ICO = await ethers.deployContract("ICO1");
    await ICO.waitForDeployment();

    const ICO2 = await ethers.deployContract("ICO2");
    await ICO2.waitForDeployment();

    const ICO3 = await ethers.deployContract("ICO3");
    await ICO3.waitForDeployment();

    const NACNFT = await ethers.deployContract("NACNFT");
    await NACNFT.waitForDeployment();

    const ClaimRewards = await ethers.deployContract("ClaimRewards");
    await ClaimRewards.waitForDeployment();

    await ICO.setNacAddr(NAC.target);
    await ICO2.setNacAddr(NAC.target);
    await ICO3.setNacAddr(NAC.target);

    await ICO.setNacClaim(ClaimRewards.target);
    await ICO2.setNacClaim(ClaimRewards.target);
    await ICO3.setNacClaim(ClaimRewards.target);

    await ClaimRewards.setNacAddr(NAC.target);

    await NAC.setWhiteStatus(ICO.target,true);
    await NAC.setWhiteStatus(ICO2.target,true);
    await NAC.setWhiteStatus(ICO3.target,true);
    await NAC.setWhiteStatus(ClaimRewards.target,true);
    
    //ICO 2
    await NAC.connect(nacVault).approve(ICO.target,'4800000000000000000000000000')
    await NAC.connect(nacVault).approve(ICO2.target,'4800000000000000000000000000')
    await NAC.connect(nacVault).approve(ICO3.target,'4800000000000000000000000000')

    console.log('============USDT address ============')

    console.log(usdtAddress)
    
    console.log('============NAC address ============')
    console.log(NAC.target)

    console.log('============NACNFT address ============')
    console.log(NACNFT.target)

    console.log('============ClaimRewards address ============')
    console.log(ClaimRewards.target)

    console.log('============ICO1 address ============')
    console.log(ICO.target)

    console.log('============ICO2 address ============')
    console.log(ICO2.target)

    console.log('============ICO3 address ============')
    console.log(ICO3.target)

 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

