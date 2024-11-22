// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
//超级管理员
contract BasicAuth {
    address public _owner;
    address public _bakOwner;
    



    constructor(address bakOwner) {
      _owner = msg.sender;
      _bakOwner = bakOwner;

    }

    function setOwner(address owner)
        public
        isAuthorized
    {
        _owner = owner;
    }

    function setBakOwner(address owner)
        public
        isAuthorized
    {
        _bakOwner = owner;
    }

    // 判断是否有超级管理员权限
    
    modifier isAuthorized() { 
        require(msg.sender == _owner || msg.sender == _bakOwner, "BasicAuth: only owner or back owner is authorized.");
        _; 
    }
}