// bored-ape.test.ts


const expect = require("chai");
const hardhat = require("hardhat");


async function main() {
    let userInfoContract;
   // let owner;
   // let address1;

 
    const UserInfo = await hardhat.ethers.getContractFactory("UserInfo");

   // [owner, address1] = await hardhat.ethers.getSigners();
   // console.log( owner);
   // console.log( address1);
    userInfoContract = await UserInfo.deploy( "0xDB2a449486E183A9cFf47ba66aCfEEd1C0200D65");
  
     console.log( await  userInfoContract._owner());
     console.log( await  userInfoContract._bakOwner());

};
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
  