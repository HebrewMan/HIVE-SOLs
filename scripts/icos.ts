import { ethers } from "hardhat";
async function main() {
    const [nacOwner, nacVault, addr3 ] = await ethers.getSigners();
    
    const nacAddress = "0x363d624545c33F032cE35FFD0Ab952F06084b0f9"; 
  
    const NAC = await ethers.getContractAt("NAC", nacAddress,nacOwner);

    const ICO1 = await ethers.deployContract("ICO1");
    await ICO1.waitForDeployment();
    
    const ICO2 = await ethers.deployContract("ICO2");
    await ICO2.waitForDeployment();
    
    const ICO3 = await ethers.deployContract("ICO3");
    await ICO3.waitForDeployment();

    console.log('============ICO1 address ============')
    console.log(ICO1.target)

    console.log('============ICO2 address ============')
    console.log(ICO2.target)

    console.log('============ICO3 address ============')
    console.log(ICO3.target)

    await NAC.setWhiteStatus(ICO1.target,true);
    await NAC.setWhiteStatus(ICO2.target,true);
    await NAC.setWhiteStatus(ICO3.target,true);
 
    await NAC.connect(nacVault).approve(ICO1.target,'100000000000000000000000')
    await NAC.connect(nacVault).approve(ICO2.target,'100000000000000000000000')
    await NAC.connect(nacVault).approve(ICO3.target,'100000000000000000000000')

    console.log("|||||||||||||DONE||||||||||||||")

 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

