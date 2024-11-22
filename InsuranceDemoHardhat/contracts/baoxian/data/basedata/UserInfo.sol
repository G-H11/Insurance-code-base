// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  

import "../../manager/BasicAuth.sol";
  //用户信息
contract UserInfo  is BasicAuth {  
   constructor(address bakOwner) BasicAuth(bakOwner){
     
  }
   //用户核心信息公钥加密存储，前端私钥解密查看
    struct User {  
        uint userId;
        string name;  //姓名
        string gender;  //性别
        uint birthdate;  //出生日期
        string idNumber;  //身份证
        string email;  //电子邮件
        string phoneNumber;  //联系电话
        string addr;  //地址
        uint8 roleId;//角色id,超级管理员1、 管理员2、保险制定3、保险审核人4、医护人员录入5、医护人员审核6、法医录入人员7、法医审核人员8、普通用户9
        bool isDeath;//注册时默认false ，未死亡
        bool isAudit;//死亡是否审核
    }  
    //客户ID 对应数据
    mapping (address => User) private users;  

   //key:idNumber  value： userEncryptedKey指纹特征加密私钥数据
    mapping (string=>string) private  EncryptedKeyDatas ;

    //授权账号存储，
    //mapping(address => mapping(address => bool)) private allowance;
    
    //公司信息，不进行机密存储职位等
    struct EmployData {  
        string idNumber;  //已加密的身份证
        string position;//职位
        string companyId; //公司id
        string creditInformation;//信用信息，违规信息
        bool isAudit; //是否审核,超级管理员审核：管理员 ，管理员：审核本公司员工
    }  
    //用户公钥地址 对应数据
    mapping (address => EmployData) private   employDatas; 

    // 添加客户信息 
    function addUser(uint userId,string memory name, string memory gender, uint birthdate, string memory idNumber, string memory email, string memory phoneNumber, string memory addr, uint8 roleId ) public {  
        require( userId !=0 &&users[tx.origin].userId == 0,"userInfo already exits or parma userId equal 0"); //用户id为默认值，添加用户,参数用户id 不能为0； 
       //新增
        users[tx.origin] = User(  userId,name, gender,birthdate,idNumber,email,phoneNumber,addr,roleId,false,false);  
          
    }  

    // 修改其他信息
    function updateUser(uint userId,string memory name, string memory gender, uint birthdate, string memory idNumber, string memory email, string memory phoneNumber, string memory addr) public {  
        require(userId !=0 && users[tx.origin].userId == userId ,"userInfo already exits or parma userId equal 0"); //用户id为默认值，添加用户,参数用户id 不能为0； 
        //修改,userId 相等并且不为零
            users[tx.origin].name= name;
            users[tx.origin].gender= gender;
            users[tx.origin].birthdate = birthdate;
            users[tx.origin].idNumber = idNumber;
            users[tx.origin].email = email;
            users[tx.origin].phoneNumber = phoneNumber;
            users[tx.origin].addr = addr;           
         
    }  

  
    // 获取客户信息 
    function getUser() public  view returns ( User memory _user) {  
        return users[tx.origin];  
        
    }  

 
  //指纹加密私钥数据插入
    function setEncryptedKeyValue(string memory value) public {  
        string memory idNumber =  users[msg.sender].idNumber;
        require(bytes(EncryptedKeyDatas[idNumber]).length==0, "User must be verified to call this");  
        EncryptedKeyDatas[idNumber] = value;  
    }  
  //指纹加密私钥数据获取
    function getEncryptedKeyValue()  public view returns (string memory) {  
        string memory idNumber =  users[msg.sender].idNumber;
        require(bytes(EncryptedKeyDatas[idNumber]).length==0, "User must be verified to call this");  
        return EncryptedKeyDatas[idNumber];  
    }  
    




   //法医修改是否死亡
    function setUserDeath(address uAddr,bool isDeath) public {  
        //校验是否授权
      require(users[tx.origin].roleId == 7,"your are not  add"); 
      users[uAddr].isDeath = isDeath;  
         
    }  

   //法医修改审核
    function setUserDeathAudit(address uAddr,bool isAudit) public {  
        //校验是否授权
       require(users[tx.origin].roleId == 8,"your are not  audit"); 
      // require(users[auidtAddr].roleId == 8,"your are not  audit");
       users[uAddr].isAudit = isAudit;  
         
    }  




    //公司、医院、法医等用户注册，注册是不需要填写角色，超级管理员（处理公司管理员），公司管理员（处理本公司相关人员）
    function registerAdmin(string memory idNumber, string memory position, string memory companyId  ) public {
        employDatas[tx.origin] = EmployData(idNumber,position,companyId,"",false);
     }


    //  超级管理员审核（只有超级管理员操作）。前端提供相应质料申请哪个账号为本公司管理员
    function auditAdmin(address uAddr) public isAuthorized(){
      if(users[uAddr].roleId !=2){ //审核一次，不允许第二次更改
        users[uAddr].roleId=2;
      }
      employDatas[uAddr].isAudit = true;
    }

    // 账号管理设置，本公司admin操作，普通用户注册后，admin赋权
    function auditEmploy(address uAddr,uint8 roleId,bool isAudit) public {
      //同一公司管理员权限
       require(compareStr(employDatas[uAddr].companyId,employDatas[tx.origin].companyId) && users[tx.origin].roleId==2,"only permission can do this");
       require(roleId !=2,"roleId  is 2 , admin can't have permission");//管理员不能设置管理员，一个公司默认一个管理员
       users[uAddr].roleId = roleId;//赋值权限
       employDatas[uAddr].isAudit = isAudit;  //公司审核为true
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

    //event Approval(address indexed owner, address indexed spender, bool value);

    //购买保险授权查看个人信息，生病授权医生查看信息等。毫无意义
    /*function approve(address spender, bool isAllowance) external returns (bool) {
        allowance[tx.origin][spender] = isAllowance;
        emit Approval(tx.origin, spender, isAllowance);
        return true;
    }*/

    //获取数据，根据用户地址，查询用户信息
    function getUserByOtherPerson(address uAddr) public view returns ( User memory user) {  
      //校验是否授权
      //require( allowance[uAddr][msg.sender],"your are not  applove");
      return users[uAddr];  
       
    }  

    function getEmployData(address userAddr) public view returns(EmployData memory _employData){
       //require( allowance[userAddr][msg.sender],"your are not  applove");
       return employDatas[userAddr];
    }

    function getEmployData() public view returns(EmployData memory _employData){
       return employDatas[tx.origin];
    }

}