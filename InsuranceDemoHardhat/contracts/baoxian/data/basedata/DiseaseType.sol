// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
import "../../manager/BasicAuth.sol";
  //疾病维度元数据
contract DiseaseType is BasicAuth {  
   constructor(address bakOwner) BasicAuth(bakOwner){
     
  }
    //uint8 roleId; 
    mapping (uint => string) private   diseaseTypes;  

   //管理员添加
    function setDiseaseType(uint diseaseTypeId,string memory diseaseName) public  isAuthorized(){
      diseaseTypes[diseaseTypeId] = diseaseName;
    }

    //获取疾病名称
    function getDiseaseType(uint diseaseTypeId) public view returns(string memory diseaseName){
      return diseaseTypes[diseaseTypeId] ;
    }
    


  
  
  
}