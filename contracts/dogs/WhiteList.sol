// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteList is Ownable {

    mapping (address => bool) public whiteLists;

    constructor(){}

    function setWhiteList(address _addr,bool _status)external onlyOwner{
        whiteLists[_addr] = _status;
    }   

}