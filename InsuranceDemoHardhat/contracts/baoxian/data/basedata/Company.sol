// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  

  import "../../manager/BasicAuth.sol";
//存储公司信息
contract Company   is BasicAuth {   
   constructor(address bakOwner) BasicAuth(bakOwner){
     
  }
  struct CompanyData{
       // string companyId; //公司id
        string companyName;  //公司名称
        address payAddress;//支付地址
  }

  //存储公司支付账号
    mapping( string => CompanyData)   companyDataS;
  //只有管理员才能设置
    function setData(string memory companyId,string memory companyName,address payAddress) public  isAuthorized(){
       companyDataS[companyId] = CompanyData(companyName,payAddress);
    }

    function getData(string memory companyId) public view returns( address payAddress){
      return companyDataS[companyId].payAddress;
    }
}