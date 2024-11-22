// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
import "../basedata/UserInfo.sol";
import "../insurancedata/CustomerMdeicalInsurance.sol";
import "../insurancedata/MdeicalInsurancePolicy.sol";

//医疗记录
contract MedicalRecord {  
    UserInfo private  userInfo;
    CustomerMdeicalInsurance private customerMdeicalInsurance;
     MdeicalInsurancePolicy private  mdeicalInsurancePolicy;
    constructor(address _userInfo, address _customerMdeicalInsurance,address _mdeicalInsurancePolicy) {
      userInfo = UserInfo(_userInfo);
      customerMdeicalInsurance = CustomerMdeicalInsurance(_customerMdeicalInsurance);
      mdeicalInsurancePolicy = MdeicalInsurancePolicy(_mdeicalInsurancePolicy);
    }
    //医疗记录加密，使用病人公钥加密，医院可查询自己系统医疗数据
    //住院记录,一次性录入，考虑保险理赔一次，第二次不理赔吗
    struct MedicalRecordData{
        string companyId; //就诊医院id
        uint TimeOfDiagnosis;//诊时间
        uint diseaseTypeId;//疾病类型
        string symptom;//症状
       // string pastMedicalHistory;//既往史
        string cause;//病因
        uint day;//住院天数
        uint money;//住院费用
        address hostpitolAdd;//录入人员
        address hostpitolAuidt;//审核人员
        bool isAudit;//判断是否审核
    }
    struct Patient{
        uint recordCnt;
        mapping (uint => MedicalRecordData) records;//病历
        bool exist; //挂号使用字段
    }
    
    //存储所有病人基本信息
    mapping (address  => Patient) private   patientDatas;  

   //医院记录插入事件
   event insertRecodeEvt(string indexed eventType, address patientAddr,string  symptom ,string  cause,  uint day,uint money,address hostpitolAuidt);
   //审核事件
   event insertAudit(string indexed eventType,address patientAddr) ;

        //查看病人信息是否存在,即是否挂号
   function isPatientExist(address patientAddr) public view returns (bool){
      return patientDatas[patientAddr].exist ;
   }
  
   //挂号
   function initPatient(string memory companyId) public{
        uint  currentRecordCnt = patientDatas[tx.origin].recordCnt;
        //避免重复挂号
        require( patientDatas[tx.origin].records[currentRecordCnt].TimeOfDiagnosis != 0,"your are already init");
        patientDatas[tx.origin].exist =true;
        patientDatas[tx.origin].recordCnt +=1;
        uint recordCnt = patientDatas[tx.origin].recordCnt;
        patientDatas[tx.origin].records[recordCnt].companyId = companyId;
       
       
   }
   //插入医院诊疗记录,权限控制
   function insertPatient(address patientAddr,uint diseaseTypeId,string memory symptom ,string memory cause,  uint day,uint money,address hostpitolAuidt) public {
      require( isPatientExist(patientAddr),"patient data not exist");//先挂号，再插入诊疗记录
       uint index = patientDatas[patientAddr].recordCnt;//获取挂号
       string memory pCompanyId = patientDatas[patientAddr].records[index].companyId; 
       string memory uCompanyId = userInfo.getEmployData().companyId;
       //医护人员所属单位，与患者治理单位一致
      require(userInfo.getUser().roleId==5&& compareStr(pCompanyId,uCompanyId),"your are not have permition");
     // patientDatas[patientAddr].recordCnt +=1;
     
      string memory companyId=  patientDatas[patientAddr].records[index].companyId;
      MedicalRecordData memory recode = MedicalRecordData(companyId,block.timestamp,diseaseTypeId,symptom,cause,day,money,tx.origin,hostpitolAuidt,false);
      patientDatas[patientAddr].records[index] = recode;
      emit insertRecodeEvt("insRecord", patientAddr, symptom, cause, day,money, hostpitolAuidt);

   }

       //审核医院诊疗记录，权限如何控制呢
   function insertPatientAudit(address patientAddr,uint recordCnt) public {
      uint  currentRecordCnt = patientDatas[patientAddr].recordCnt;
      require( isPatientExist(patientAddr) &&patientDatas[patientAddr].records[currentRecordCnt].TimeOfDiagnosis != 0,"patient data not exist");
    
       string memory pCompanyId = patientDatas[patientAddr].records[currentRecordCnt].companyId; 
       string memory uCompanyId = userInfo.getEmployData().companyId;
       //医护人员所属单位，与患者治理单位一致
      require(userInfo.getUser().roleId==6&& compareStr(pCompanyId,uCompanyId),"your are not have permition");
      
      patientDatas[patientAddr].records[recordCnt].isAudit=true ;
      patientDatas[patientAddr].records[recordCnt].hostpitolAuidt =tx.origin;

   }




   //病历查看，投保人确保无保险约束疾病内容（购买保险时）
   function getPatientData(string memory companyId,uint  insurerceId) public view returns(bool isdiseaseTypeIn){
      uint [] memory diseaseTypeIds = mdeicalInsurancePolicy.getMedicalInsuranceDatas(companyId, insurerceId).diseaseTypeIds;
      uint nextIndex = mdeicalInsurancePolicy.getMedicalInsuranceDatas(companyId, insurerceId).nextIndex;
      uint recordCnt = patientDatas[tx.origin].recordCnt;
      for(uint i = 1;i <=recordCnt ;i++){
        uint diseaseTypeId = patientDatas[tx.origin].records[i].diseaseTypeId;
        for(uint j = 0; j<nextIndex;j++){
            if(diseaseTypeIds[j] == diseaseTypeId){
              return true;
            }
        }
        
      }
     return false;
   } 
   
   //理赔时查看时间范围对不对


   //根据记录id，查自己病历
   function getPatientData(uint recodeId) public view returns(MedicalRecordData memory _medicalRecordData){

       require(patientDatas[tx.origin].records[recodeId].isAudit,"your record is not audit");
       _medicalRecordData=patientDatas[tx.origin].records[recodeId];

   } 
   //查询patientDatas,保险审核人员调用，有病例不准购买保险，无用的方法
  /* function getPatientDatas(address custAddr) public view returns(MedicalRecordData [] memory _medicalRecordData){
       string memory custCompanyId = customerMdeicalInsurance.getInsurance(custAddr).companyId;//客户购买保险的公司
       string memory uCompanyId = userInfo.getEmployData().companyId;//保险人员公司
       
      //权限控制,保险审核人员
      require(userInfo.getUser().roleId==4 && compareStr(custCompanyId,uCompanyId),"your are not have permision");
      for(uint i =1 ; i <= patientDatas[tx.origin].recordCnt;i++ ){
        if( patientDatas[tx.origin].records[i].isAudit){ //查看审核通过的病历
          _medicalRecordData[i]=patientDatas[custAddr].records[i];
        }
      }
   } */
     //受益人查询patientDatas，权限如何控制呢
   function getPatientDataByBeneficiarie(uint recodeId) public view returns(MedicalRecordData memory _medicalRecordData){
      require(customerMdeicalInsurance.getInsuranceBeneficiarie().order !=0,"your are not have permision");//检查受益人是有受益的权限
      address userId = customerMdeicalInsurance.getInsuranceBeneficiarie().userId;
      require( isPatientExist(userId),"patient data not exist");
      require( patientDatas[userId].records[recodeId].isAudit,"patient data recode not audit or not exist");
      return patientDatas[userId].records[recodeId];
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
