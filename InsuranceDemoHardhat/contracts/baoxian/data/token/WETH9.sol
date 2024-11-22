// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
import "../basedata/UserInfo.sol";
import "../medicaldata/MedicalRecord.sol";
import "../insurancedata/CustomerMdeicalInsurance.sol";
import "../insurancedata/MdeicalInsurancePolicy.sol";
import "../basedata/Company.sol";
contract WETH9 {

   UserInfo private  userInfo;
   MedicalRecord private medicalRecord;
   CustomerMdeicalInsurance private customerMdeicalInsurance;
   MdeicalInsurancePolicy private  mdeicalInsurancePolicy;
   Company private  company;
   constructor(address _userInfo ,address _medicalRecord,address _customerMdeicalInsurance,address _mdeicalInsurancePolicy,address _company) {
      userInfo = UserInfo(_userInfo);
      medicalRecord = MedicalRecord(_medicalRecord);
      customerMdeicalInsurance = CustomerMdeicalInsurance(_customerMdeicalInsurance);
      mdeicalInsurancePolicy = MdeicalInsurancePolicy(_mdeicalInsurancePolicy);
      company = Company(_company);
  }
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

   
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad, "");
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    //投保人转账
    function atuoTransfer(address src, uint wad,uint recodeId) public returns (bool) {
        //需要检查tx.orgin 是否有对应保险
        require(customerMdeicalInsurance.getInsurance().isAudit && customerMdeicalInsurance.getInsurance().enrollmentEndDate <=block.timestamp,""); 
        //理赔金额为医院诊疗记录金额
        require(medicalRecord.getPatientData(recodeId).money <= wad,""); //输入理赔金额，少于等于 看病金额
        //转账src地址与tx.orgin 的对应保险公司名称一致
        require(company.getData(customerMdeicalInsurance.getInsurance().companyId) == src,"" ); 
        //理赔了不能重复理赔
        require(customerMdeicalInsurance.getInsurance().claimStatus ==0,"" ); //等于0未理赔
        balanceOf[src] -= wad;
        balanceOf[msg.sender] += wad;
        emit Transfer(src, msg.sender, wad);
        return true;
    }
    //死亡受益人转账
    function atuoBeneficiarieTransfer(address src, uint wad,uint recodeId) public returns (bool) {
        //需要检查tx.orgin 是否有对应保险
        require(customerMdeicalInsurance.getInsuranceByBeneficiarie().isAudit && customerMdeicalInsurance.getInsuranceByBeneficiarie().enrollmentEndDate<= block.timestamp,""); 
        //理赔金额为医院诊疗记录金额
         uint insurerceId = customerMdeicalInsurance.getInsuranceByBeneficiarie().insurerceId;
         string memory companyId = customerMdeicalInsurance.getInsuranceByBeneficiarie().companyId;
         uint payMoney =medicalRecord.getPatientDataByBeneficiarie(recodeId).money;//查看保险赔付金额
         uint claimAmout;
        if(customerMdeicalInsurance.getInsuranceBeneficiarie().order ==1 ){
            uint  deathOdds1 = mdeicalInsurancePolicy.getMedicalInsuranceDatas(companyId,insurerceId).deathOdds1;//获取受益人1的赔率
            claimAmout = payMoney*deathOdds1;
        }else{
           uint  deathOdds2 = mdeicalInsurancePolicy.getMedicalInsuranceDatas(companyId,insurerceId).deathOdds2;//获取受益人2的赔率
           claimAmout = payMoney*deathOdds2;
        }
        require(claimAmout <= wad,""); //输入理赔金额，少于等于 看病金额
        //转账src地址与tx.orgin 的对应保险公司名称一致
        require(company.getData( companyId) == src,"" ); 
        //理赔了不能重复理赔
        require(customerMdeicalInsurance.getInsurance(customerMdeicalInsurance.getInsuranceBeneficiarie().userId).claimStatus ==0,"" ); //等于0未理赔
        balanceOf[src] -= wad;
        balanceOf[msg.sender] += wad;
        emit Transfer(src, msg.sender, wad);
        return true;
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad, "");

        if (src != msg.sender && allowance[src][msg.sender] != uint(0)) {
            require(allowance[src][msg.sender] >= wad, "");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
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