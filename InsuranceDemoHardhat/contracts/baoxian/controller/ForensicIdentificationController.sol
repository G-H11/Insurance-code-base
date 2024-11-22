// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


import "../data/basedata/UserInfo.sol";


//法医死亡鉴定
contract ForensicIdentificationController {
 
   UserInfo private  userInfo;


   constructor(address _userInfo ) {
      userInfo = UserInfo(_userInfo);

   }
   //考虑替换userInfo 的地址，合约升级，不考虑数据迁移

   //法医注册

  //权限
   modifier onlyHavePermissionsAdd(){
     require(userInfo.getUser().roleId == 7,"your are not have add permission");  
     _;
   }
   modifier onlyHavePermissionsAudit(){
     require(userInfo.getUser().roleId == 8,"your are not have autid permission");  
     _;
  }
   //死亡录入
   function addDeath(address addr) public onlyHavePermissionsAdd {
      userInfo.setUserDeath( addr,true) ;
   }

   //死亡审核
   function auditDeath(address addr) public onlyHavePermissionsAudit{
      userInfo.setUserDeathAudit(addr,true);
   }


}