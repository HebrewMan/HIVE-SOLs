import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre, { ethers } from "hardhat";

  describe("Lock", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployApproveFixture() {

        const usdtAddress = "0x4128a6b222F4d37C66fe4f8AEcaf2c79467C08EE"; 
        const nacAddress = "0xFcD4130195ae5D504E2e360De6c4551d8e65820B"; 

        const USDT = await ethers.getContractAt("USDT", usdtAddress);
        const NAC  = await ethers.getContractAt("NAC", nacAddress);

        const [nacOwner, usdtOwner, addr3 ] = await hre.ethers.getSigners();

        const Ico = await hre.ethers.getContractFactory("ICO1");
        const ICO = await Ico.deploy();

        await NAC.setWhiteStatus(ICO.getAddress(),true);
        await NAC.setWhiteStatus(nacOwner,true);

        await NAC.approve(ICO.getAddress(),'100000000000000000000000000');

        return { USDT, NAC, ICO,nacOwner, usdtOwner, addr3 ,usdtAddress,nacAddress};
    }
  
    describe("MintNAC", function () {
        it("Should set the right unlockTime", async function () {
            const { addr3, ICO ,USDT} = await loadFixture(deployApproveFixture);

            
            
            try {
                console.log(USDT);
                
                // const tx = await USDT.connect(addr3).approve(ICO.getAddress(),'10000000000000');
                // await tx.wait();
                // console.log('============USDT approve =========');
                // console.log(tx.hash);
                
                // const tx2 = await ICO.mintNAC(_addr10,_addr5);
                // console.log('============ MintNAC =========');
                // console.log(tx2.hash);
            } catch (error) {
                console.log(error);
                
            }

            // expect(await lock.unlockTime()).to.equal(unlockTime);
        });
     
    });
  
   
  });
  