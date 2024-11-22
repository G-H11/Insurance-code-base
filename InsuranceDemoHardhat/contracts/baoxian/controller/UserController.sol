// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  
import "../data/basedata/UserInfo.sol";
import "../data/medicaldata/MedicalRecord.sol";
import "../data/insurancedata/CustomerMdeicalInsurance.sol";
import "../data/insurancedata/MdeicalInsurancePolicy.sol";
import "../data/token/WETH9.sol";
import "../data/basedata/Company.sol";
//存储公司信息
contract UserController   {   

   UserInfo private  userInfo;
   MedicalRecord private medicalRecord;
   CustomerMdeicalInsurance private customerMdeicalInsurance;
   MdeicalInsurancePolicy private  mdeicalInsurancePolicy;
   WETH9 private  weth9;
   Company private  company;
   constructor(address _userInfo ,address _medicalRecord,address _customerMdeicalInsurance,address _mdeicalInsurancePolicy,address _weth9,address _company) {
      userInfo = UserInfo(_userInfo);
      medicalRecord = MedicalRecord(_medicalRecord);
      customerMdeicalInsurance = CustomerMdeicalInsurance(_customerMdeicalInsurance);
      mdeicalInsurancePolicy = MdeicalInsurancePolicy(_mdeicalInsurancePolicy);
      weth9 = WETH9(payable(_weth9));
      company = Company(_company);
  }
  //考虑替换userInfo 的地址，合约升级，不考虑数据迁移


  //用户注册
  function register(uint userId,string memory name, string memory gender, uint birthdate, string memory idNumber, string memory email, string memory phoneNumber, string memory addr, uint8 roleId ) public{
      userInfo.addUser(userId,name, gender,birthdate,idNumber,email,phoneNumber,addr,roleId);
  }
  //用户信息更新
  function updateUserInfo(uint userId,string memory name, string memory gender, uint birthdate, string memory idNumber, string memory email, string memory phoneNumber, string memory addr) public{
      userInfo.updateUser(userId,name, gender,birthdate,idNumber,email,phoneNumber,addr);
  }

  //购买保险，查看病历，是否有能购买
  function buyInsurance(uint  insurerceId,string memory companyId, string memory insuranceType, uint paymentAmount,address beneficiaries1,address beneficiaries2, address insurerceEmployId,address insuranceAuidt) public{
   //1、根据用户地址查看用户病历,并判断病历是否审核,可以交审核人员进行审核，或者设计不能购买的疾病列表
   //要求无疾病内容，可以购买
    require(!medicalRecord.getPatientData(companyId, insurerceId),"you have  current Medical History,you are can't buy the insurance ");
   //2、购买
    customerMdeicalInsurance.buyInsurance( insurerceId,companyId, insuranceType, paymentAmount,beneficiaries1,beneficiaries2,  insurerceEmployId,insuranceAuidt);
   //3、支付代币,先1:1 用eth 兑换 weth 代表，再转账
    weth9.deposit();
    address payAddress = company.getData(companyId);
    weth9.transfer(payAddress, paymentAmount) ;
     

 }
  //挂号
  function initPatient(string memory companyId) public {
    medicalRecord.initPatient( companyId);
  }

  //自动理赔  isOwnerInsurance=ture 投保人 ，false 保险死亡受益人
  //前台用户可选择对应病历，进行理赔，所以传参recodeId
  function claims(uint recodeId,bool isOwnerInsurance) public{
     //1、判读是否有保险 2、是否死亡 3、根据具体情况，保险赔率计算金额 4、更新理赔金额
    // require(customerMdeicalInsurance.getInsurance().insurerceId ==0,"your insurance is not have");
    if(isOwnerInsurance == true && !userInfo.getUser().isDeath && userInfo.getUser().isAudit  ){
        require(customerMdeicalInsurance.getInsurance().isAudit ,"your insurance is not insured");//保险生效
        require(customerMdeicalInsurance.getInsurance().enrollmentEndDate<= block.timestamp,"your insurance is off.");//在保期限内
        string memory companyId = customerMdeicalInsurance.getInsurance().companyId;
        uint insurerceId = customerMdeicalInsurance.getInsurance().insurerceId;
        uint payMoney =medicalRecord.getPatientData(recodeId).money;
        //计算金额
        uint claimAmout = mdeicalInsurancePolicy.getMedicalInsuranceDatas(companyId,insurerceId).odds * payMoney;
        //更新理赔金额
        customerMdeicalInsurance.updateInsurance( claimAmout);
        //eth转账，转的是代币，后续可提现
        address payAddress = company.getData(companyId);
        weth9.atuoTransfer(payAddress,claimAmout,recodeId);

    }else{//受益人调用
        require(customerMdeicalInsurance.getInsuranceByBeneficiarie().isAudit ,"your insurance is not insured");//保险生效
        require(customerMdeicalInsurance.getInsuranceByBeneficiarie().enrollmentEndDate<= block.timestamp,"your insurance is off.");//在保期限内
        string memory companyId = customerMdeicalInsurance.getInsuranceByBeneficiarie().companyId;
        uint insurerceId = customerMdeicalInsurance.getInsuranceByBeneficiarie().insurerceId;
        //address userId =customerMdeicalInsurance.getInsuranceBeneficiarie().userId;//死亡受益人 获取 保险购买者地址
        uint payMoney =medicalRecord.getPatientDataByBeneficiarie(recodeId).money;//获取保险购买者的治理费用
        uint claimAmout;
        //其他受益人受益
        if(customerMdeicalInsurance.getInsuranceBeneficiarie().order ==1 ){
            uint  deathOdds1 = mdeicalInsurancePolicy.getMedicalInsuranceDatas(companyId,insurerceId).deathOdds1;//获取受益人1的赔率
            claimAmout = payMoney*deathOdds1;
        }else{
           uint  deathOdds2 = mdeicalInsurancePolicy.getMedicalInsuranceDatas(companyId,insurerceId).deathOdds2;//获取受益人2的赔率
           claimAmout = payMoney*deathOdds2;
        }
      
        customerMdeicalInsurance.updateInsurance(claimAmout);//修改保险赔付金额
        //转eth，转的是代币，后续可提现
        address payAddress = company.getData(companyId);
        weth9.atuoBeneficiarieTransfer(payAddress,claimAmout,recodeId);
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