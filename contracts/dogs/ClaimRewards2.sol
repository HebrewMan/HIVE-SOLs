// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SignTool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ClaimRewards2 is SignTool{

    event Claimed(address user,address token ,uint claimAmount,uint nonce);

    function claim(address _token,uint _claimAmount,uint _endTime,uint _nonce,bytes calldata _signature)external{
        require(userNonce[msg.sender] == _nonce,"Nonce: Nonce error");
        require(block.timestamp <= _endTime,"Time:The signature has expired.");

        bytes32 _msgHash = getUserMessageHash(msg.sender,_token, _claimAmount,_endTime,_nonce);
        require(verify(_msgHash, _signature), "Signature: Error signature.");

        userNonce[msg.sender] ++;

        IERC20(_token).transfer(msg.sender,_claimAmount);

        emit Claimed(msg.sender,_token,_claimAmount,_nonce);
    }

    fallback() external payable {}
    receive() external payable {}

}
