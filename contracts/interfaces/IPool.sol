// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IPOOL {

    //wirth funcs
    function supply()external;
    function borrow()external;
    function withdraw()external;
    function repay()external;
    function liquidationCall()external;

    //read pool
    //
    

    //read user
}
