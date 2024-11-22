// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
import "../data/basedata/UserInfo.sol";
import "../data/medicaldata/MedicalRecord.sol";
import "../data/insurancedata/CustomerMdeicalInsurance.sol";
import "../data/insurancedata/MdeicalInsurancePolicy.sol";
//保险公司
contract InsuranceController   {   
    UserInfo private  userInfo;
    MedicalRecord private medicalRecord;
    CustomerMdeicalInsurance private customerMdeicalInsurance;
    MdeicalInsurancePolicy private  mdeicalInsurancePolicy;

    constructor(address _userInfo ,address _medicalRecord,address _customerMdeicalInsurance,address _mdeicalInsurancePolicy) {
        userInfo = UserInfo(_userInfo);
        medicalRecord = MedicalRecord(_medicalRecord);
        customerMdeicalInsurance = CustomerMdeicalInsurance(_customerMdeicalInsurance);
        mdeicalInsurancePolicy = MdeicalInsurancePolicy(_mdeicalInsurancePolicy);
    }
    //申请加入

    //保险信息录入

    //保险信息录入审核

    //保险信息修改

    //保险信息查看
    
    //清算
    function getFunds() public {
        
    }

      
}