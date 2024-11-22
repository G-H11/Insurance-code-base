// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;

// 类型转换的实用方法
contract Utils {

    function stringToBytes32(string memory source)  internal pure  returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x)  internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            
            bytes1 char = bytes1(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    } 
     
    function compareStrings (string memory a, string memory b) internal pure returns (bool) {
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
   }
}

// 旅客列表合约
contract TravelerOwnerList is Utils {  
    address[] public travelerOwnerList; // 存储合约的地址  
    mapping(address => address) public creatorOwnerMap; // 将创建者的地址映射到TravelerOwner合约的地址  
  
    function createTravelerOwner(address _PaymentRecordList, address _BuyFlightRecordList, address _BuySchemeRecordList, string memory userName, string memory password, bool gender, string memory phone)  
    public {  
        address ownerAccount = msg.sender;  
        require(isNotRegistered(ownerAccount),"The travelerOwner account is not registered!Please register !");  
        address newTravelerOwner = address(new TravelerOwner(_PaymentRecordList, _BuyFlightRecordList, _BuySchemeRecordList, ownerAccount, userName, password, gender, phone));  
        travelerOwnerList.push(newTravelerOwner);  
        creatorOwnerMap[ownerAccount] = newTravelerOwner;  
    }  
  
    function isNotRegistered(address account) internal view returns (bool) {  
        return creatorOwnerMap[account] == address(0); // 如果账户没有创建合约，映射的默认值是0  
    }  
  
    function verifyPwd(string memory userName, string memory password) public view returns (bool) {  
        address creator = msg.sender;  
        require(!isNotRegistered(creator),"The travelerOwner account is not registered!Please register !");  
        address contractAddr = creatorOwnerMap[creator];  
        TravelerOwner travelerOwner = TravelerOwner(contractAddr);  
        return compareStrings(travelerOwner.userName(), userName) && travelerOwner.pwdRight(password);  
    }  
  
    function getTravelerOwnerList() public view returns (address[] memory) {  
        return travelerOwnerList;  
    }  
  
    function isTravelerOwner(address ownerAddr) public view returns (bool) {  
        for (uint i = 0; i < travelerOwnerList.length; i++) {  
            if (ownerAddr == travelerOwnerList[i]) 
                return true;  
        }  
        return false;  
    }  
}

// 旅客合约
contract TravelerOwner is Utils{
    address public owner;//who create the contract through register
    address public paymentRecordList;
    address public buyFlightRecordList;
    address public buySchemeRecordList;
    string public userName;
    bytes32 private password;
    uint private nowBalance;
    bool public gender;
    string public phone;

    struct Traveler {
        uint travelerId;
        string travelerNumber;
        string travelerName;
        uint8 travelerAge;
        uint buyRecordId;//the buying record id array of this car
        bool isValid;// used for mapping to judge if the key has the corresponding value
    }

    modifier ownerOnly {
        require(msg.sender==owner,"Permissions are insufficient, and only the account owner can use them !");
        _;
    }

    modifier ownerOrSystemOnly {
        require(msg.sender==owner||msg.sender==paymentRecordList||msg.sender==buyFlightRecordList||msg.sender==buySchemeRecordList,"The permissions are insufficient, and only system personnel can use them !");
        _;
    }

    uint[] public travelers;//store cars' carId
    mapping(uint=>Traveler) travelerMap;//get the car according to its id

    constructor(address _PaymentRecordList,address _BuyFlightRecordList, address _BuySchemeRecordList, address _owner,string memory _userName,string memory _pwd,bool _gender,string memory _phone)  {
        owner = _owner;
        paymentRecordList = _PaymentRecordList;
        buyFlightRecordList = _BuyFlightRecordList;
        buySchemeRecordList = _BuySchemeRecordList;
        userName = _userName;
        password = stringToBytes32(_pwd);
        nowBalance = 10000;
        gender = _gender;
        phone = _phone;
    }

    function pwdRight(string memory _pwd) public view returns (bool) {
        return password==stringToBytes32(_pwd);
    }

    function getBalance() public view ownerOrSystemOnly returns (uint) {
        return nowBalance;
    }

    function modifyOwnerInfo(string  memory _userName,bool _gender,string  memory _phone) public ownerOnly {
        userName = _userName;
        gender = _gender;
        phone = _phone;
    }

    function updateBalance(int increment) public ownerOrSystemOnly {
        require((int(nowBalance)+increment)>=0,"The balance is insufficient and the payment is in arrears !");
        nowBalance = uint(int(nowBalance) + increment);
    }

    function updatePassword(string memory newPwd) public ownerOnly {
        password = stringToBytes32(newPwd);
    }

    function getOwnerInfo() public view returns(string memory ,bool,string memory){
        return (userName,gender,phone);
    }

    //add a car by carNumber,carName,carAge, the default buyRecordId is zero
    function addTraveler(string memory travelerNumber, string memory travelerName, uint8 travelerAge) public ownerOnly {  
        require(notRepeated(travelerNumber),"The number already exists, please re-enter it !");  
        uint nowTravelerId = travelers.length > 0 ? travelers[travelers.length - 1] + 1 : 1;  
        travelers.push(nowTravelerId);  
        travelerMap[nowTravelerId].travelerId = nowTravelerId;  
        travelerMap[nowTravelerId].travelerNumber = travelerNumber;  
        travelerMap[nowTravelerId].travelerName = travelerName;  
        travelerMap[nowTravelerId].travelerAge = travelerAge;  
        travelerMap[nowTravelerId].buyRecordId = 0; // 表示尚未购买保险  
        travelerMap[nowTravelerId].isValid = true;  
    }  

    function notRepeated(string memory travelerNumber) internal view returns (bool) {  
        for (uint i = 0; i < travelers.length; i++) {  
            if (compareStrings(travelerMap[i].travelerNumber, travelerNumber)) return false;  
        }  
        return true;  
    }  

    function getTravelerIds() public view returns (uint[] memory) {  
        return travelers;  
    }  

    function getTravelerInfoById(uint id) public view returns (uint, string memory, string memory, uint8, uint) {  
        Traveler storage target = travelerMap[id];  
        return (target.travelerId, target.travelerNumber, target.travelerName, target.travelerAge, target.buyRecordId);  
    }  

    function buyInsurance(uint travelerId, uint buyRecordId) public ownerOrSystemOnly {  
        require(travelerMap[travelerId].isValid,"The passenger ID is invalid !");  
        travelerMap[travelerId].buyRecordId = buyRecordId;  
    }
}

// 保险公司列表合约
contract CompanyList is Utils {
    address[] public companyList;
    mapping(address=>address) public creatorCompanyMap;//in web3.js get the corresponding contract addr through CompanyList(account)
    function createCompany(address _PaymentRecordList, address _BuyFlightRecordList, address _BuySchemeRecordList, string memory userName,string memory password,string memory phone,string memory companyNo) public {
        address companyAccount = msg.sender;
        require(isNotRegistered(companyAccount),"The company account is not registered!Please register !");
        address newCompany = address(new Company(_PaymentRecordList, _BuyFlightRecordList, _BuySchemeRecordList, companyAccount,userName,password,phone,companyNo));
        companyList.push(newCompany);
        creatorCompanyMap[companyAccount] = newCompany;
    }

    function getCompanyList() public view returns (address[] memory){
        return companyList;
    }

    function isNotRegistered(address account) internal view returns (bool) {
        return creatorCompanyMap[account]== address(0);//if account hasn't created contract,the mapping's default value is 0
    }

    function isCompany(address companyAddr) public view returns (bool) {
        for(uint i = 0; i < companyList.length; i++) {
            if(companyAddr==companyList[i]) return true;
        }
        return false;
    }

    function verifyPwd(string  memory userName,string memory password) public view returns (bool) {
        address creator = msg.sender;
        require(!isNotRegistered(creator),"The company account is not registered!Please register !");
        address contractAddr = creatorCompanyMap[creator];
        Company company = Company(contractAddr);
        return compareStrings(company.userName(),userName)&&company.pwdRight(password);
    }
}

// 保险公司合约
contract Company is Utils {
    address public owner; //who create the company by registering as a company
    address public paymentRecordList;
    address public buyFlightRecordList;
    address public buySchemeRecordList;
    string public userName;
    bytes32 private password;
    uint private nowBalance;
    string public phone;
    string public companyNo;

    constructor(address _PaymentRecordList, address _BuyFlightRecordList, address _BuySchemeRecordList, address _owner,string memory _userName,string memory _password,string memory _phone,string  memory _companyNo)  {
        owner = _owner;
        paymentRecordList = _PaymentRecordList;
        buyFlightRecordList = _BuyFlightRecordList;
        buySchemeRecordList = _BuySchemeRecordList;
        userName = _userName;
        password = stringToBytes32(_password);
        nowBalance = 10000;
        phone = _phone;
        companyNo = _companyNo;
    }

    modifier ownerOnly {
        require(owner==msg.sender,"Permissions are insufficient, and only the account owner can use them !");
        _;
    }

    modifier ownerOrSystemOnly {
        require(msg.sender==owner||msg.sender==paymentRecordList||msg.sender==buyFlightRecordList||msg.sender==buySchemeRecordList,"The permissions are insufficient, and only system personnel can use them !");
        _;
    }

    function modifyCompanyInfo(string  memory _userName,string memory _phone,string memory _companyNo) public ownerOnly {
        userName = _userName;
        phone = _phone;
        companyNo = _companyNo;
    }

    function updatePassword(string memory newPwd) public ownerOnly{
        password = stringToBytes32(newPwd);
    }

    function pwdRight(string  memory _pwd) public view returns (bool) {
        return password==stringToBytes32(_pwd);
    }

    function updateBalance(int increment) public ownerOrSystemOnly{
        require((int(nowBalance)+increment) > 0,"The balance is insufficient and the payment is in arrears !");
        nowBalance = uint(int(nowBalance) + increment);
    }

    function getBalance() public view ownerOrSystemOnly returns (uint){
        return nowBalance;
    }

    function getCompanyInfo() public view returns (string memory ,string memory,string memory) {
        return (userName,phone,companyNo);
    }

    uint[] public schemeIds;
    mapping(uint=>Scheme) schemes;
    struct Scheme {
        uint Id;
        string schemeName;
        uint lastTime;
        uint price;
        uint payOut;
        bool onSale;
        bool isValid;
    }

    function addScheme(string  memory schemeName,uint lastTime,uint price,uint payOut) public ownerOnly{
        uint nowSchemeId = schemeIds.length>0?schemeIds[schemeIds.length-1]+1:1;
        schemeIds.push(nowSchemeId);
        schemes[nowSchemeId].Id = nowSchemeId;
        schemes[nowSchemeId].schemeName = schemeName;
        schemes[nowSchemeId].lastTime = lastTime;
        schemes[nowSchemeId].price = price;
        schemes[nowSchemeId].payOut = payOut;
        schemes[nowSchemeId].onSale = true;
        schemes[nowSchemeId].isValid = true;
    }

    function setOnSale(uint schemeId,bool onSale) public ownerOnly{
        require(existScheme(schemeId),"This insurance ID is invalid or non-existent!");
        schemes[schemeId].onSale = onSale;
    }

    function getSchemeIds() public view returns (uint[] memory) {
        return schemeIds;
    }

    function getSchemeInfoById(uint schemeId) public view returns (uint,string memory,uint,uint,uint,bool){
        require(existScheme(schemeId),"This insurance ID is invalid or non-existent !");
        Scheme storage scheme = schemes[schemeId];
        return (scheme.Id,scheme.schemeName,scheme.lastTime,scheme.price,scheme.payOut,scheme.onSale);
    }

    function existScheme(uint schemeId) internal view returns (bool) {
        return schemes[schemeId].isValid;
    }
}

// 航空公司列表合约
contract AirlineList is Utils {
    address[] public airlineList;
    mapping(address=>address) public creatorAirlineMap;//in web3.js get the corresponding contract addr through CompanyList(account)
    function createAirline(address _PaymentRecordList, address _BuyFlightRecordList, address _BuySchemeRecordList, string memory userName,string memory password,string memory phone,string memory airlineNo) public {
        address airlineAccount = msg.sender;
        require(isNotRegistered(airlineAccount),"The Airline account is not registered ! Please register !");
        address newAirline = address(new Airline(_PaymentRecordList, _BuyFlightRecordList, _BuySchemeRecordList, airlineAccount,userName,password,phone,airlineNo));
        airlineList.push(newAirline);
        creatorAirlineMap[airlineAccount] = newAirline;
    }

    function getAirlineList() public view returns (address[] memory){
        return airlineList;
    }

    function isNotRegistered(address account) internal view returns (bool) {
        return creatorAirlineMap[account]== address(0);//if account hasn't created contract,the mapping's default value is 0
    }

    function isAirline(address airlineAddr) public view returns (bool) {
        for(uint i = 0; i < airlineList.length; i++) {
            if(airlineAddr==airlineList[i]) return true;
        }
        return false;
    }

    function verifyPwd(string  memory userName,string memory password) public view returns (bool) {
        address creator = msg.sender;
        require(!isNotRegistered(creator),"The Airline account is not registered ! Please register !");
        address contractAddr = creatorAirlineMap[creator];
        Airline airline = Airline(contractAddr);
        return compareStrings(airline.userName(),userName)&&airline.pwdRight(password);
    }
}

// 航空公司合约
contract Airline is Utils {  
    address public owner; //who create the company by registering as a company
    address public paymentRecordList;
    address public buyFlightRecordList;
    address public buySchemeRecordList;
    string public userName;
    bytes32 private password;
    uint private nowBalance;
    string public phone;
    string public airlineNo;

    constructor(address _PaymentRecordList, address _BuyFlightRecordList, address _BuySchemeRecordList, address _owner,string memory _userName,string memory _password,string memory _phone,string  memory _airlineNo)  {
        owner = _owner;
        paymentRecordList = _PaymentRecordList;
        buyFlightRecordList = _BuyFlightRecordList;
        buySchemeRecordList = _BuySchemeRecordList;
        userName = _userName;
        password = stringToBytes32(_password);
        nowBalance = 10000;
        phone = _phone;
        airlineNo = _airlineNo;
    }

    modifier ownerOnly {
        require(owner==msg.sender,"Permissions are insufficient, and only the account owner can use them !");
        _;
    }

    modifier ownerOrSystemOnly {
        require(msg.sender==owner||msg.sender==paymentRecordList||msg.sender==buyFlightRecordList||msg.sender==buySchemeRecordList,"The permissions are insufficient, and only system personnel can use them !");
        _;
    }

    function modifyCompanyInfo(string  memory _userName,string memory _phone,string memory _airlineNo) public ownerOnly {
        userName = _userName;
        phone = _phone;
        airlineNo = _airlineNo;
    }

    function updatePassword(string memory newPwd) public ownerOnly{
        password = stringToBytes32(newPwd);
    }

    function pwdRight(string  memory _pwd) public view returns (bool) {
        return password==stringToBytes32(_pwd);
    }

    function updateBalance(int increment) public ownerOrSystemOnly{
        require((int(nowBalance)+increment) > 0,"The balance is insufficient and the payment is in arrears !");
        nowBalance = uint(int(nowBalance) + increment);
    }

    function getBalance() public view ownerOrSystemOnly returns (uint){
        return nowBalance;
    }

    function getAirlineInfo() public view returns (string memory ,string memory,string memory) {
        return (userName,phone,airlineNo);
    }  

    uint[] public flightIds;
    mapping(uint=>Flight) flights;
    struct Flight {
        uint Id;
        string flightName;
        uint planFlyTime;
        uint actualFlyTime;
        uint price;
        uint processState; // 航班状态  0-提前  1-按时  2-延迟 
        uint delay;        // 延时时长 
        bool onSale;       // 出售的状态 true-在售（有票）  false-售罄（无票）
        bool isValid;      // 航班信息 true-正常  false-异常（航班取消）
    }

    function addFlight(string  memory flightName,uint planFlyTime,uint price,uint processState) public ownerOnly{
        uint nowFlightId = flightIds.length>0 ? flightIds[flightIds.length-1]+1 : 1;
        flightIds.push(nowFlightId);
        flights[nowFlightId].Id = nowFlightId;
        flights[nowFlightId].flightName = flightName;
        flights[nowFlightId].planFlyTime = planFlyTime;
        flights[nowFlightId].actualFlyTime = planFlyTime;
        flights[nowFlightId].price = price;
        flights[nowFlightId].processState = processState;
        flights[nowFlightId].delay = 0;
        flights[nowFlightId].onSale = true;
        flights[nowFlightId].isValid = true;
    }

    function setOnSale(uint flightId,bool onSale) public ownerOnly{
        require(existFlight(flightId),"This flight ID is invalid or non-existent !");
        flights[flightId].onSale = onSale;
    }

    function setDelay(uint flightId,uint delay) public ownerOnly{
        require(existFlight(flightId),"This flight ID is invalid or non-existent !");
        flights[flightId].delay = delay;
        flights[flightId].actualFlyTime =flights[flightId].planFlyTime + delay;
    }

    function getFlightIds() public view returns (uint[] memory) {
        return flightIds;
    }

    function getFlightInfoById(uint flightId) public view returns (uint,string memory,uint,uint,bool){
        require(existFlight(flightId),"This flight ID is invalid or non-existent !");
        Flight storage flight = flights[flightId];
        return (flight.Id,flight.flightName,flight.planFlyTime,flight.price,flight.onSale);
    }

    function existFlight(uint flightId) internal view returns (bool) {
        return flights[flightId].isValid;
    }
}

// 购买航班记录列表合约
contract BuyFlightRecordList {
    uint[] flightRecordList;

    mapping(uint=>BuyFlightRecord) buyFlightRecords;

    struct BuyFlightRecord{
        uint Id;  
        address travelerOwner;   
        uint travelerId;  
        address airline;  
        uint flightId;  
        uint startTime; 
        uint processState; // 0 is waiting for process, 1 is approve, 2 is reject  
        uint Balance; // 存储来自travelerOwner或公司的临时资金，用于事故赔付   
        bool isValid;
    }

    function getFlightRecordList() public view returns (uint[] memory){  
        return flightRecordList; // 假设recordList已经定义  
    }  
  
    function getBuyFlightRecordById(uint recordId) public view returns (uint,address,uint,address,uint,uint,uint,uint){  
        require(existFlightRecord(recordId),"This flight ID is invalid or non-existent !"); // 假设existRecord函数已经定义  
        BuyFlightRecord storage buyFlightRecord = buyFlightRecords[recordId]; // 假设buyRecords是一个映射，并且已经定义  
        return (buyFlightRecord.Id, buyFlightRecord.travelerOwner, buyFlightRecord.travelerId, buyFlightRecord.airline,  
            buyFlightRecord.flightId, buyFlightRecord.startTime, buyFlightRecord.processState, buyFlightRecord.Balance);  
    }  
  
    // 根据公司地址查找BuyRecord的id  
    function getBuyFlightRecordIdsByAirline(address airline) public view returns (uint[] memory){  
        uint k = 0;  
        for(uint i = 0; i < flightRecordList.length; i++) {  
            if(buyFlightRecords[flightRecordList[i]].airline == airline) k++;  
        }  
        uint[] memory recordIds = new uint[](k);  
        k = 0;  
        for(uint i = 0; i < flightRecordList.length; i++) {  
            if(buyFlightRecords[flightRecordList[i]].airline == airline) {  
                recordIds[k++] = flightRecordList[i];  
        }  
    }  
        return recordIds;  
    }

    function existFlightRecord(uint recordId) public  view returns (bool) {
        return buyFlightRecords[recordId].isValid;//isValid==true means such record exists
    }

    function addBuyFlightRecord(address travelerOwnerListAddr, address travelerOwner, uint travelerId, address airline, uint flightId, uint startTime, uint price) public {  
        TravelerOwner travelerOwnerContract = TravelerOwner(travelerOwner);  
        require(msg.sender == travelerOwnerContract.owner(),"The Traveler accounts do not match, please switch accounts !");  
        TravelerOwnerList travelerOwnerList = TravelerOwnerList(travelerOwnerListAddr);  
        require(travelerOwnerList.isTravelerOwner(travelerOwner),"Note! Illegal Accounts !");  
        require(travelerOwnerContract.getBalance() > price,"The Traveler balance is insufficient !");  
        travelerOwnerContract.updateBalance(-int(price)); // Subtract traveler's balance  
        uint nowBuyRecordId = flightRecordList.length > 0 ? flightRecordList[flightRecordList.length - 1] + 1 : 1;  
        flightRecordList.push(nowBuyRecordId);  
        buyFlightRecords[nowBuyRecordId].Id = nowBuyRecordId;  
        buyFlightRecords[nowBuyRecordId].travelerOwner = travelerOwner;  
        buyFlightRecords[nowBuyRecordId].travelerId = travelerId;  
        buyFlightRecords[nowBuyRecordId].airline = airline;  
        buyFlightRecords[nowBuyRecordId].flightId = flightId;  
        buyFlightRecords[nowBuyRecordId].startTime = startTime;  
        buyFlightRecords[nowBuyRecordId].processState = 0;  
        buyFlightRecords[nowBuyRecordId].Balance = price;  
        buyFlightRecords[nowBuyRecordId].isValid = true;  
        travelerOwnerContract.buyInsurance(travelerId, nowBuyRecordId); // Assuming this function also exists and is updated accordingly  
    }

    //return the last buyRecord's id
    function getLastBuyFlightRecordId() public view returns(uint) {
         return flightRecordList[flightRecordList.length-1];
    }

    function doBuyFlightRecord(address airlineListAddr, address airlineAddr, uint recordId, bool approve) public {  
        require(existFlightRecord(recordId),"This flight ID is invalid or non-existent !");  
        Airline airlineContract = Airline(airlineAddr);  
        require(airlineContract.owner() == msg.sender,"The Airline accounts do not match, please switch accounts !"); // Only company can do buyRecord  
        AirlineList airlineList = AirlineList(airlineListAddr);
        require(airlineList.isAirline(airlineAddr),"The airline address does not exist !");  
        BuyFlightRecord storage buyFlightRecord = buyFlightRecords[recordId];  
        require(buyFlightRecord.airline == airlineAddr,"The flight does not exist for the airline !"); // 记录的公司地址必须等于companyAddr  
        require(buyFlightRecord.processState == 0,"The transaction has been processed or declined !"); // 记录是未处理的  

        if (approve) {
            airlineContract.updateBalance(int(buyFlightRecord.Balance)); // 转账给公司  
            buyFlightRecord.Balance = buyFlightRecord.Balance - buyFlightRecord.Balance;  
            buyFlightRecord.processState = 1;  
        } else {  
            TravelerOwner travelerOwner = TravelerOwner(buyFlightRecord.travelerOwner);   
            travelerOwner.updateBalance(int(buyFlightRecord.Balance)); // 将钱退还给travelerOwner  
            buyFlightRecord.Balance = 0;  
            buyFlightRecord.processState = 2;  
        }  
    }

    function updateBuyFlightRecordBalance(uint recordId,uint newBalance) public {
        BuyFlightRecord storage buyFlightRecord = buyFlightRecords[recordId];
        buyFlightRecord.Balance = newBalance;
    }

    //process the balance of those buy records who are out of date
    function cleanOutOfDate(uint recordId, address airlineListAddr, address airlineAddr) public {  
        require(existFlightRecord(recordId),"This flight ID is invalid or non-existent !");  
        Airline airline = Airline(airlineAddr);  
        require(airline.owner() == msg.sender,"Accounts don't match !"); // Only airline can dopaymentRecord  
        AirlineList airlineList = AirlineList(airlineListAddr);  
        require(airlineList.isAirline(airlineAddr),"Attention, illegal airline accounts !");  
        BuyFlightRecord storage buyFlightRecord = buyFlightRecords[recordId];  
  
        Airline targetAirline = Airline(buyFlightRecord.airline);  
        // send the balance of the buyRecord to target company  
        targetAirline.updateBalance(int(buyFlightRecord.Balance));  
        buyFlightRecord.Balance = 0;  
    }
}

// 购买保险纪录列表合约
contract BuySchemeRecordList {

    uint[] schemeRecordList;

    mapping(uint=>BuySchemeRecord) buySchemeRecords;

    struct BuySchemeRecord {  
        uint Id;  
        address travelerOwner; // 修改了carOwner为travelerOwner  
        uint travelerId; // 修改了carId为travelerId  
        address company;  
        uint schemeId;  
        uint startTime;  
        uint processState; // 0 is waiting for process, 1 is approve, 2 is reject  
        uint Balance; // 存储来自travelerOwner或公司的临时资金，用于事故赔付  
        bool isValid;  
    }  
  
    function getRecordList() public view returns (uint[] memory){  
        return schemeRecordList; // 假设recordList已经定义  
    }  
  
    function getBuyRecordById(uint recordId) public view returns (uint,address,uint,address,uint,uint,uint,uint){  
        require(existSchemeRecord(recordId),"This Scheme ID is invalid or non-existent !"); // 假设existRecord函数已经定义  
        BuySchemeRecord storage buySchemeRecord = buySchemeRecords[recordId]; // 假设buyRecords是一个映射，并且已经定义  
        return (buySchemeRecord.Id, buySchemeRecord.travelerOwner, buySchemeRecord.travelerId, buySchemeRecord.company,  
            buySchemeRecord.schemeId, buySchemeRecord.startTime, buySchemeRecord.processState, buySchemeRecord.Balance);  
    }  
  
    // 根据公司地址查找BuyRecord的id  
    function getBuyRecordIdsByCompany(address company) public view returns (uint[] memory){  
        uint k = 0;  
        for(uint i = 0; i < schemeRecordList.length; i++) {  
            if(buySchemeRecords[schemeRecordList[i]].company == company) k++;  
        }  
        uint[] memory recordIds = new uint[](k);  
        k = 0;  
        for(uint i = 0; i < schemeRecordList.length; i++) {  
            if(buySchemeRecords[schemeRecordList[i]].company == company) {  
                recordIds[k++] = schemeRecordList[i];  
        }  
    }  
        return recordIds;  
    }

    function existSchemeRecord(uint recordId) internal view returns (bool) {
        return buySchemeRecords[recordId].isValid;//isValid==true means such record exists
    }

    function addBuySchemeRecord(address travelerOwnerListAddr, address travelerOwner, address buyFlightRecordListAddr,uint flightRecordId,uint travelerId, address company, uint schemeId, uint startTime) public {  
        TravelerOwner travelerOwnerContract = TravelerOwner(travelerOwner);  
        require(msg.sender == travelerOwnerContract.owner(),"The traveler does not exist !");  
        TravelerOwnerList travelerOwnerList = TravelerOwnerList(travelerOwnerListAddr);  
        require(travelerOwnerList.isTravelerOwner(travelerOwner),"The traveler does not exist !");  
        require(travelerOwnerContract.getBalance() > 10,"The account balance is insufficient !");  
        BuyFlightRecordList buyFlightRecordList = BuyFlightRecordList(buyFlightRecordListAddr);
        require(buyFlightRecordList.existFlightRecord(flightRecordId),"This Flight ID is invalid or non-existent !");
        travelerOwnerContract.updateBalance(-int(10)); // Subtract traveler's balance  
        uint nowBuyRecordId = schemeRecordList.length > 0 ? schemeRecordList[schemeRecordList.length - 1] + 1 : 1;  
        schemeRecordList.push(nowBuyRecordId);  
        buySchemeRecords[nowBuyRecordId].Id = nowBuyRecordId;  
        buySchemeRecords[nowBuyRecordId].travelerOwner = travelerOwner;  
        buySchemeRecords[nowBuyRecordId].travelerId = travelerId;  
        buySchemeRecords[nowBuyRecordId].company = company;  
        buySchemeRecords[nowBuyRecordId].schemeId = schemeId;  
        buySchemeRecords[nowBuyRecordId].startTime = startTime;  
        buySchemeRecords[nowBuyRecordId].processState = 0;  
        buySchemeRecords[nowBuyRecordId].Balance = 10;  
        buySchemeRecords[nowBuyRecordId].isValid = true;  
        travelerOwnerContract.buyInsurance(travelerId, nowBuyRecordId); // Assuming this function also exists and is updated accordingly  

    }

    //return the last buyRecord's id
    function getLastBuyRecordId() public view returns(uint) {
         return schemeRecordList[schemeRecordList.length-1];
    }

    function doSchemeBuyRecord(address companyListAddr, address companyAddr, uint recordId, bool approve,uint maxPayout) public {  
        require(existSchemeRecord(recordId),"This Scheme ID is invalid or non-existent !");  
        Company companyContract = Company(companyAddr);  
        require(companyContract.owner() == msg.sender,"The Company accounts do not match, please switch accounts !"); // Only company can do buyRecord  
        CompanyList companyList = CompanyList(companyListAddr);
        require(companyList.isCompany(companyAddr),"The Company address does not exist !");  
        BuySchemeRecord storage buySchemeRecord = buySchemeRecords[recordId];  
        require(buySchemeRecord.company == companyAddr,"The Company does not exist for the Scheme !"); // 记录的公司地址必须等于companyAddr  
        require(buySchemeRecord.processState == 0,"The transaction has been processed or declined !"); // 记录是未处理的  
  
        if (approve) {  
            maxPayout = 1000;
            companyContract.updateBalance(int(buySchemeRecord.Balance) - int(maxPayout)); // 转账给公司  
            buySchemeRecord.Balance = maxPayout;  
            buySchemeRecord.processState = 1;  
        } else {  
            TravelerOwner travelerOwner = TravelerOwner(buySchemeRecord.travelerOwner); // 将CarOwner替换为TravelerOwner  
            travelerOwner.updateBalance(int(buySchemeRecord.Balance)); // 将钱退还给travelerOwner  
            buySchemeRecord.Balance = 0;  
            buySchemeRecord.processState = 2;  
        }  
    }

    function updateBuyRecordBalance(uint recordId,uint newBalance) public {
        BuySchemeRecord storage buySchemeRecord = buySchemeRecords[recordId];
        buySchemeRecord.Balance = newBalance;
    }

    //process the balance of those buy records who are out of date
    function cleanOutOfDate(uint recordId, address companyListAddr, address companyAddr) public {  
        require(existSchemeRecord(recordId),"This Scheme ID is invalid or non-existent !");  
        Company company = Company(companyAddr);  
        require(company.owner() == msg.sender,"The company address does not match !"); // Only airline can dopaymentRecord  
        CompanyList companyList = CompanyList(companyListAddr);  
        require(companyList.isCompany(companyAddr),"The Company address does not exist !");  
        BuySchemeRecord storage buySchemeRecord = buySchemeRecords[recordId];  
  
        Company targetCompany = Company(buySchemeRecord.company);  
        // send the balance of the buyRecord to target company  
        targetCompany.updateBalance(int(buySchemeRecord.Balance));  
        buySchemeRecord.Balance = 0;  
    }
}

// 赔付纪录列表合约
contract PaymentRecordList {
    uint[] recordList;
    mapping(uint=>PaymentRecord) paymentRecords;

    struct PaymentRecord {
        uint Id;
        address travelerOwner;
        uint travelerId;
        address airline;
        //accident information
        uint time;
        string describe;//addr,damage,roadLevel,roadQuality,trafficDescribe,alchhol,speed,accelarate
        uint delay;//the carOwner's loss in the accident
        address company;
        uint schemeId;
        uint payout;
        bool isValid;
    }

    function addPaymentRecord(address airlineListAddr, address airlineOwner,address travelerOwner, uint travelerId, uint time, string memory describe,  
        address company, uint schemeId, uint delay) public {  
        Airline airlineOwnerContract = Airline(airlineOwner);  
        require(airlineOwnerContract.owner()==msg.sender,"The airline address does not match !"); // Only travelerOwner can add PaymentRecord  
        AirlineList airlineList = AirlineList(airlineListAddr);  
        require(airlineList.isAirline(airlineOwner),"The Airline does not exist !");  

        uint nowPaymentRecordId = recordList.length > 0 ? recordList[recordList.length - 1] + 1 : 1;  
        recordList.push(nowPaymentRecordId);  
        paymentRecords[nowPaymentRecordId].Id = nowPaymentRecordId;  
        paymentRecords[nowPaymentRecordId].travelerOwner = travelerOwner;  
        paymentRecords[nowPaymentRecordId].travelerId = travelerId;  
        paymentRecords[nowPaymentRecordId].airline = address(0);  
        paymentRecords[nowPaymentRecordId].time = time;  
        paymentRecords[nowPaymentRecordId].describe = describe;  
        paymentRecords[nowPaymentRecordId].delay = delay;  
        paymentRecords[nowPaymentRecordId].payout = 0;  
        paymentRecords[nowPaymentRecordId].company = company;  
        paymentRecords[nowPaymentRecordId].schemeId = schemeId;  
        paymentRecords[nowPaymentRecordId].isValid = true;  
    }

    function getRecordList() public view returns (uint[] memory){
        return recordList;
    }

    function getRecordIdsByOwnerAddr(address travelerOwnerAddr) public view returns (uint[] memory) {  
        uint k = 0;  
        for(uint i = 0; i < recordList.length; i++) {  
            if(paymentRecords[recordList[i]].travelerOwner == travelerOwnerAddr) k++;  
        }  
        uint[] memory recordIds = new uint[](k);  
        k = 0;  
        for(uint i = 0; i < recordList.length; i++) {  
            if(paymentRecords[recordList[i]].travelerOwner == travelerOwnerAddr) {  
                recordIds[k++] = recordList[i];  
            }  
        }  
        return recordIds;  
    }

    function getRecordIdsByCompanyAddr(address companyAddr) public view returns (uint[] memory) {
        uint k = 0;
        for(uint i = 0; i < recordList.length; i++) {
            if(paymentRecords[recordList[i]].company==companyAddr) k++;
        }
        uint[] memory recordIds = new uint[](k);
        k = 0;
        for(uint i = 0; i < recordList.length; i++) {
            if(paymentRecords[recordList[i]].company==companyAddr) {
                recordIds[k++] = recordList[i];
            }
        }
        return recordIds;
    }

    function getRecordIdsByAirlineAddr(address airlineAddr) public view returns (uint[] memory) {
        uint k = 0;
        for(uint i = 0; i < recordList.length; i++) {
            if(paymentRecords[recordList[i]].airline==airlineAddr) k++;
        }
        uint[] memory recordIds = new uint[](k);
        k = 0;
        for(uint i = 0; i < recordList.length; i++) {
            if(paymentRecords[recordList[i]].airline==airlineAddr) {
                recordIds[k++] = recordList[i];
            }
        }
        return recordIds;
    }

    function getUndoRecordIds() public view returns(uint[] memory){

        uint k = 0;
        for(uint i = 0; i < recordList.length; i++) {
            if(paymentRecords[recordList[i]].delay <= 4) k++;
        }
        uint[] memory recordIds = new uint[](k);
        k = 0;
        for(uint i = 0; i < recordList.length; i++) {
            if(paymentRecords[recordList[i]].delay <= 4) {
                recordIds[k++] = recordList[i];
            }
        }
        return recordIds;
    }

    function getRecordInfoById(uint recordId) public view
    returns(uint,address,uint,uint,string memory,uint,address,uint,address,uint){
        require(existPaymentRecord(recordId),"This PaymentRecord ID is invalid or non-existent !");
        PaymentRecord storage paymentRecord = paymentRecords[recordId];
        return (paymentRecord.Id,paymentRecord.travelerOwner,paymentRecord.travelerId,
                paymentRecord.time,paymentRecord.describe,paymentRecord.delay,
                paymentRecord.company,paymentRecord.schemeId,
                paymentRecord.airline,paymentRecord.payout);
    }

    function existPaymentRecord(uint recordId) internal view returns (bool) {
        return paymentRecords[recordId].isValid;//isValid==true means such record exists
    }

    function doPaymentRecord(uint paymentRecordId, address companyAddr, address companyListAddr,address buySchemeRecordListAddr, uint buySchemeRecordId,     
        address travelerOwnerAddr,uint buyRecordAvail) public {    
        require(existPaymentRecord(paymentRecordId),"This PaymentRecord ID is invalid or non-existent !");    
        Company company = Company(companyAddr);    
        require(company.owner() == msg.sender,"The insurance company's address does not match !"); // Only company can doPaymentRecord    
        CompanyList companyList = CompanyList(companyListAddr);    
        require(companyList.isCompany(companyAddr),"Please note that this insurance company is not covered by the insurance company !"); 
        PaymentRecord storage paymentRecord = paymentRecords[paymentRecordId];
        BuySchemeRecordList buySchemeRecordList = BuySchemeRecordList(buySchemeRecordListAddr);    
        TravelerOwner travelerOwner = TravelerOwner(travelerOwnerAddr);  
        if (getDelay(paymentRecordId)){
            uint payOut = getPayout(buyRecordAvail);
            // transfer payOut to travelerOwner    
            travelerOwner.updateBalance(int(payOut));    
            // updateBuyRecordBalance with new available balance    
            buySchemeRecordList.updateBuyRecordBalance(buySchemeRecordId, buyRecordAvail - payOut);    
            paymentRecord.payout = payOut;  
        } 
        else {
            company.updateBalance(int(buyRecordAvail));
        }
          
    }

    function getDelay(uint paymentRecordId) internal view  returns (bool){
        PaymentRecord storage paymentRecord = paymentRecords[paymentRecordId];
        return paymentRecord.delay < 4 ? false : true;
    }

    function getPayout(uint avail) internal pure returns (uint){
        uint payOut = avail;
        return payOut;
    }
}
