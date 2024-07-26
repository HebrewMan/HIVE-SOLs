import { ethers } from "ethers";

async function main() {

    const provider = ethers.getDefaultProvider("https://data-seed-prebsc-1-s3.bnbchain.org:8545");
    const price = (await provider.getFeeData()).gasPrice;

    console.log('当前gas 价格是 ======》 ',price);
    
 }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

