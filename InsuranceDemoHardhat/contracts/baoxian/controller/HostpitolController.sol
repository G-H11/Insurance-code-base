// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "../data/basedata/UserInfo.sol";
import "../data/medicaldata/MedicalRecord.sol";

//医院用户端
contract HostpitolController  {

    UserInfo private  userInfo;
    MedicalRecord private medicalRecord;


    constructor(address _userInfo ,address _medicalRecord) {
      userInfo = UserInfo(_userInfo);
      medicalRecord = MedicalRecord(_medicalRecord);

    }
 
    //注册,管理员代码为2,医护人员审核5,医护人员6、
    function register(uint userId,string memory name, string memory gender, uint birthdate, string memory idNumber, string memory email, string memory phoneNumber, string memory addr,uint8 roleId, string memory position, string memory companyId ) public {
       userInfo.addUser(userId,name, gender, birthdate, idNumber,email, phoneNumber, addr, roleId ); 
       userInfo.registerAdmin(idNumber,position,companyId);
    }
    //授权替他人查看本人信息
    /* function approve(address spender, bool isAllowance) public{
       userInfo.approve(spender,isAllowance);
     }*/
    //查看员工信息,信息是加密的，因此需要公司自己系统数据，用用户公钥加密，与区块链数据进行比对，校验真实性
    function getRegisterInfo(address uAddr) public view returns(uint userId,string memory name, string memory gender, uint birthdate, string memory idNumber, string memory email, string memory phoneNumber, string memory addr, uint8 roleId,string memory position,bool isAudit){
       //本公司员工，以及角色为admin
       string memory _companyId = userInfo.getEmployData(uAddr).companyId;
       require(compareStr(userInfo.getEmployData(msg.sender).companyId ,_companyId)&&userInfo.getUser().roleId == 2);
       userId =userInfo.getUserByOtherPerson(uAddr).userId;
       name =userInfo.getUserByOtherPerson(uAddr).name;
       gender =userInfo.getUserByOtherPerson(uAddr).gender;
       birthdate =userInfo.getUserByOtherPerson(uAddr).birthdate;
       idNumber =userInfo.getUserByOtherPerson(uAddr).idNumber;
       email =userInfo.getUserByOtherPerson(uAddr).email;
       phoneNumber =userInfo.getUserByOtherPerson(uAddr).phoneNumber;
       addr =userInfo.getUserByOtherPerson(uAddr).addr;
       roleId =userInfo.getUserByOtherPerson(uAddr).roleId;
       position = userInfo.getEmployData(uAddr).position;
       isAudit = userInfo.getEmployData(uAddr).isAudit;
      
    }

    //审核普通员工
    function registerAudit(address uAddr,bool isAudit,uint8 roleId) public {
        //本公司员工，以及角色为admin
       require(compareStr(userInfo.getEmployData(msg.sender).companyId ,userInfo.getEmployData(uAddr).companyId)&&userInfo.getUser().roleId == 2);
       userInfo.auditEmploy( uAddr, roleId, isAudit);
    }


    //录入诊疗记录
     function insertPatient(address patientAddr,uint  diseaseTypeId,string memory symptom ,string memory cause,  uint day,uint money,address hostpitolAuidt) public {
        require(userInfo.getUser().roleId == 5);
        medicalRecord.insertPatient(patientAddr, diseaseTypeId,symptom, cause, day, money, hostpitolAuidt);
     }
    //审核诊疗记录
    function insertPatientAudit(address patientAddr,uint recordCnt) public {
         require(userInfo.getUser().roleId == 6);
        medicalRecord.insertPatientAudit(patientAddr,recordCnt);
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