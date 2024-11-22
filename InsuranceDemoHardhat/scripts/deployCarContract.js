// bored-ape.test.ts

const fs = require('fs-extra');
const path = require('path');
const expect = require("chai");
const hardhat = require("hardhat");


async function main() {
    let accidentRecordList,buyRecordList,carOwnerList,companyList,policerList;

   // let owner;
   // let address1;

   //发布合约 "AccidentRecordList","BuyRecordList","CarOwnerList","CompanyList","PolicerList"
    const AccidentRecordList = await hardhat.ethers.getContractFactory("AccidentRecordList");
    const BuyRecordList = await hardhat.ethers.getContractFactory("BuyRecordList");
    const CarOwnerList = await hardhat.ethers.getContractFactory("CarOwnerList");
    const CompanyList = await hardhat.ethers.getContractFactory("CompanyList");
    const PolicerList = await hardhat.ethers.getContractFactory("PolicerList");

    accidentRecordList = await AccidentRecordList.deploy( );
    buyRecordList = await BuyRecordList.deploy( );
    carOwnerList = await CarOwnerList.deploy( );
    companyList = await CompanyList.deploy( );
    policerList = await PolicerList.deploy( );


    //console.log( await  accidentRecordList.getAddress());
    // console.log( await  buyRecordList.getAddress());
     const contractAddrArray = [];
     contractAddrArray.push(await accidentRecordList.getAddress());
     contractAddrArray.push(await buyRecordList.getAddress());
     contractAddrArray.push(await carOwnerList.getAddress());
     contractAddrArray.push(await companyList.getAddress());
     contractAddrArray.push(await policerList.getAddress());
      //  合约地址写入文件系统
    const addressFile = path.resolve(__dirname, './address.json');
    fs.writeFileSync(addressFile, JSON.stringify(contractAddrArray));
    console.log('地址写入成功:', addressFile);

   [owner, address1] = await hardhat.ethers.getSigners();
    console.log( owner);
    console.log( address1);

};
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
  