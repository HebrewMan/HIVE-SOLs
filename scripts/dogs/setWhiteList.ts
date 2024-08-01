import { ethers } from "hardhat";
async function main() {
    const [nacOwner, nacVault, addr3 ] = await ethers.getSigners();
    
    const nacAddress = "0x9F102c8217c258E02D46984BBb7bCC5F882bd7C1"; 
  
    const NAC = await ethers.getContractAt("NAC", nacAddress,nacOwner);
    
    await NAC.setWhiteStatus('0x3829C841d8f12303f767ccBAD8fb8cbBeFAc8e1D',true);

    const res = await NAC.whiteList('0x3829C841d8f12303f767ccBAD8fb8cbBeFAc8e1D');

    console.log(res);
    

 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

