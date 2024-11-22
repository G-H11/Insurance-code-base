// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
  import "../../manager/BasicAuth.sol";
contract Roles is BasicAuth {  
     constructor(address bakOwner) BasicAuth(bakOwner){
     
   }
    /*管理员私钥丢失怎么办,
    1、解决办法2位管理员，可以互相重新设置
    2、指纹加密私钥存储，指纹解密
    */

    /*
      多方参与，实现去中心化操作
      设置管理员的目的：管理权限，其他无权限操作
      设置超级管理员目的：给每个保险公司，每个医院自己的权限修改自己公司员工权限，其他无权限操作
    */

    //角色ID 对应数据，超级管理员1、 管理员2、保险制定3、保险审核人4、医护人员审核5、医护人员6、法医录入人员7、法医审核人员8、普通用户9
    struct Role{
       string roleType;//角色类型superadmin,admin, hospital 、insuranceCorp、customer、forensic
       string roleName;//角色名称
    }
    //uint8 roleId; 
    mapping (uint8 => Role) private   roleDatas;  

   //设置角色
    function setRole(uint8 roleId,string memory roleType,string memory roleName) public  isAuthorized(){
      roleDatas[roleId] = Role(roleType,roleName);
    }

    //获取角色
    function getRole(uint8 roleId) public view returns(Role memory role){
      return roleDatas[roleId] ;
    }
    


  
  
  
}