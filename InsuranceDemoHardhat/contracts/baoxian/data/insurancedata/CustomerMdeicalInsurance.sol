// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
import "../basedata/UserInfo.sol";
//参保信息
contract CustomerMdeicalInsurance {  
    UserInfo private  userInfo;
    constructor(address _userInfo) {
      userInfo = UserInfo(_userInfo);
     
   }
    //参保信息，不加密，按正常需要加密
    struct CustomerInsurance {  

        uint insurerceId;//保险信息id
        string companyId;//公司id
        string insuranceStatus;  //保险状态
        string insuranceType;  //保险类型
        uint insuranceAmount;  //保险金额
        uint enrollmentStartDate;  //参保开始日期
        uint enrollmentEndDate;  //参保结束日期
        string paymentStatus;  //支付状态
        uint paymentAmount;  //支付金额
        uint paymentDate;  //支付日期
        address insurerceEmployId ; //办理审核人
        uint  claimStatus; // 0:未申请理赔,  1:理赔成功  
        uint claimTotalAmout; //理赔总金额
        address insuranceAuidt;//审核人员
        bool isAudit;//判断是否审核,审核成果保险生效，复杂不生效
    }  
    //购买保险的用户公钥， 对应数据，本设计考虑 1个人购买一份保险
    mapping (address => CustomerInsurance) private  customerInsurances;  
    //受益人对应保险理赔人
    struct Beneficiarie{
        uint insurerceId;
        uint8  order;
        uint claimAmout;
        address userId;//投保人
    }
    //死亡受益人（受益人- 对应投保人）
    mapping (address => Beneficiarie) private  beneficiaries;  
    

    address public tokenContract;   // token合约地址


    //保险购买者获取保险信息
    function getInsurance() public view returns(CustomerInsurance memory _customerInsurance){
        return customerInsurances[tx.origin];
    }

    //保险公司人员查看
    function getInsurance(address custAddr) public view returns(CustomerInsurance memory _customerInsurance){
        //保险公司查看自己公司客户购买的保险，并且是审核人员审核时调用
        require(userInfo.getUser().roleId==4 &&compareStr(customerInsurances[custAddr].companyId , userInfo.getEmployData().companyId));
        return customerInsurances[custAddr];
    }

    //死亡受益人 获取保险信息
    function getInsuranceByBeneficiarie() public view returns(CustomerInsurance memory _customerInsurance){
        require(beneficiaries[tx.origin].userId != address(0x0),"your are not beneficiarie");//检查非受益人
        return customerInsurances[beneficiaries[tx.origin].userId];
    }

      //死亡受益人 获取自己信息,受益人排序
    function getInsuranceBeneficiarie() public view returns(Beneficiarie memory _beneficiarie){
        require(beneficiaries[tx.origin].userId != address(0x0),"your are not beneficiarie");//检查非受益人
        return beneficiaries[tx.origin];
    }

    //购买保险
    function buyInsurance(uint  insurerceId,string memory companyId, string memory insuranceType, uint paymentAmount,address beneficiaries1,address beneficiaries2, address insurerceEmployId,address insuranceAuidt) public {
        //保险 id 不能未0
        customerInsurances[tx.origin] = CustomerInsurance(insurerceId,companyId,"true",insuranceType,3000,
          block.timestamp,block.timestamp+360 * 24 * 60 * 60 ,"true",paymentAmount,block.timestamp,insurerceEmployId,0,0,insuranceAuidt,false);

          beneficiaries[beneficiaries1].userId = tx.origin;
          beneficiaries[beneficiaries1].order =1;
          beneficiaries[beneficiaries2].userId = tx.origin;
          beneficiaries[beneficiaries2].order =2;

    }

    //修改保险信息
    function updateInsurance(uint claimAmout) public {
        if(beneficiaries[tx.origin].userId!= address(0x0)){//受益人调用
           require(beneficiaries[tx.origin].claimAmout == 0,"can't updateInsurance,become already pay");
           customerInsurances[beneficiaries[tx.origin].userId].claimStatus = 1;
           beneficiaries[tx.origin].claimAmout = claimAmout;
           customerInsurances[beneficiaries[tx.origin].userId].claimTotalAmout += claimAmout;
        }else{//保险购买者调用
           require(customerInsurances[tx.origin].claimTotalAmout == 0,"can't updateInsurance,become already pay");
           customerInsurances[tx.origin].claimStatus = 1;
           customerInsurances[tx.origin].claimTotalAmout = claimAmout;
        }

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