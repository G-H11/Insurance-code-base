// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
import "../data/basedata/UserInfo.sol";
import "../data/medicaldata/MedicalRecord.sol";
import "../data/insurancedata/CustomerMdeicalInsurance.sol";
import "../data/insurancedata/MdeicalInsurancePolicy.sol";
//保险公司
contract AdminController   {   
    UserInfo private  userInfo;


    constructor(address _userInfo ) {
      userInfo = UserInfo(_userInfo);
    }
    //审核管理员
    function auidtAdmin(address adminAddr) public {
        userInfo.auditAdmin(adminAddr);
    }

    //角色处理

}