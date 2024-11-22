// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0 ;  
import "../basedata/UserInfo.sol";

//保险规则信息
contract MdeicalInsurancePolicy  {   

   UserInfo private  userInfo;

  constructor(address _userInfo) {
      userInfo = UserInfo(_userInfo);
  }
    //保险规则信息，不加密，公布查看
  struct MedicalInsuranceData{
        string  policyName;   // 初始化保险政策名称  
        string  policyType;  // 初始化保险政策类型  
        string  coverage;   // 初始化保险覆盖范围  
        string  premium;  // 初始化保费金额  
        string  terms;  // 初始化保险条款，后续可考虑使用IPFS进行存储  
        uint  odds; //赔率 ，填写80即，医疗费用报销80%
        //设计支持2位受益人，需要复杂，设计结构体、mapping存储受益人赔率
        uint  deathOdds1; //死亡受益人1赔率，假设填写医疗费用报销50%
        uint  deathOdds2; //死亡受益人2赔率 ，假设医疗费用报销20%
        bool  isEffect;//是否失效
        uint [] diseaseTypeIds;//不能购买的疾病类型
        uint  nextIndex ;  //数组长度
  }


    struct MedicalInsurance{
      uint recordCnt;//保险数量
      //insurerceId 取值recordCnt
      mapping(uint => MedicalInsuranceData)  medicalInsuranceDatas;//保险信息
    }


   //保险公司EOA账号，对应保险信息
    mapping(string companyId => MedicalInsurance) internal _medicalInsuranceDatas;


     //录入保险产品 
    function setInsuranceData(string memory companyId , string memory policyName, string memory policyType, string memory coverage, string memory premium, string memory terms, uint odds,uint [] memory diseaseTypeIds,uint  nextIndex)   public {       
        // 检查传入的参数
        //本保险公司录入权限可以录入
        uint8 roleId = userInfo.getUser().roleId;//保险人员
        string memory uCompanyId = userInfo.getEmployData().companyId;//保险人员
        require(compareStr(uCompanyId,companyId) && roleId==3,"only permission can do this");
        MedicalInsurance storage insurance = _medicalInsuranceDatas[companyId];  
        uint insurerceId = insurance.recordCnt+=1;
        insurance.medicalInsuranceDatas[insurerceId] = MedicalInsuranceData(policyName,policyType,coverage,premium,terms, odds, 70, 30, true,diseaseTypeIds,nextIndex);  
       
    }  

   //审核保险产品规则
    function auditInsuranceData(string memory companyId ,uint insurerceId, bool isEffect)  public {  
        //本保险公司审核权限可以审核
        uint8 roleId = userInfo.getUser().roleId;//保险人员
        string memory uCompanyId = userInfo.getEmployData().companyId;//保险人员
        require(compareStr(uCompanyId,companyId) && roleId==4,"only permission can do this");
      //检查参数是否正确
      _medicalInsuranceDatas[companyId].medicalInsuranceDatas[insurerceId].isEffect = isEffect;  
    
    }  
    
    //获取保险数据
    function getMedicalInsuranceDatas(string memory companyId,uint  insurerceId) public view returns(MedicalInsuranceData memory _MedicalInsuranceData) {
        return  _medicalInsuranceDatas[companyId].medicalInsuranceDatas[insurerceId];
    }
    
        //比较字符串函数
     function compareStr(string memory _str1, string memory _str2) public pure returns (bool){
        if (bytes(_str1).length == bytes(_str2).length) {
            if (
                keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2))
            ) {
                return true;
            }
        }
        return false;
    }
}