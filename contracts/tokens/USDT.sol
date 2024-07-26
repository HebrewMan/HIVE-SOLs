// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    address addr1 = 0xd15716734A0167FC72272A8f7a0c7c39eA9Ac89b;
    constructor() ERC20("Gold", "USDT") {
        _mint(msg.sender, 10**9 * 10**decimals());
        _mint(addr1, 10**9 * 10**decimals());
    }
}