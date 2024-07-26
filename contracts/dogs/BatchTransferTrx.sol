// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransfer {

    function batchTransfer(address payable[] calldata recipients, uint256[] calldata amounts) public payable {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");
        require(recipients.length > 0, "Recipients array must not be empty");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(totalAmount <= msg.value, "Insufficient TRX sent with the transaction");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }
}
