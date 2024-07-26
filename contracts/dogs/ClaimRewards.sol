// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SignTool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


contract ClaimRewards is SignTool{

    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public nac = 0x9F102c8217c258E02D46984BBb7bCC5F882bd7C1;
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;//v2 
    address public lpVault = 0x6128f989381CA384EAE04045F03A472D0F501b2C;
    
    IUniswapV2Router01 public Router = IUniswapV2Router01(router);

    event Claimed(address user,address token,uint burnAmount ,uint claimAmount,uint nonce);

    function setNacAddr(address _addr)external onlyOwner{
        nac = _addr;
    }

    function getPaths() public  view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = nac;
        return path;
    }

    function getNACAmountForUSDT(uint _amount) public view returns (uint256) {
        uint256 amountIn = _amount * 10 ** 18; // 100 USDT, considering the decimals
        uint256[] memory amountsOut = Router.getAmountsOut(amountIn, getPaths());
        return amountsOut[1];
    }

    function claim(address _token,uint _claimAmount,uint _burnAmount,uint _endTime,uint _nonce,bytes calldata _signature)external{
    
        require(userNonce[msg.sender] == _nonce,"Nonce: Nonce error");
        require(block.timestamp <= _endTime,"Time:The signature has expired.");

        bytes32 _msgHash = getUserMessageHash(msg.sender,_token, _claimAmount, _burnAmount,_endTime,_nonce);
        require(verify(_msgHash, _signature), "Signature: Error signature.");

        userNonce[msg.sender] ++;

        if(_burnAmount>0){
            IERC20(nac).transfer(address(0xdead),_burnAmount);
        }
        
        IERC20(_token).transfer(msg.sender,_claimAmount);

        emit Claimed(msg.sender,_token,_burnAmount,_claimAmount,_nonce);
    }

    function swapNacForUSDT(uint _usdtAmount, address _to) public onlyOwner returns (uint nacAmount) {
        IERC20(usdt).approve(router, _usdtAmount * 10000);

        uint256[] memory amountsOut = Router.getAmountsOut(_usdtAmount, getPaths());
        uint256 amountOutMin = amountsOut[1] * 95 / 100; 

        uint[] memory amounts = Router.swapExactTokensForTokens(
            _usdtAmount,
            amountOutMin,
            getPaths(),
            _to,
            block.timestamp + 10
        );

        nacAmount = amounts[1];
    }


    function addLiquidity(uint256 _usdtAmount) external onlyOwner{
        uint _nacAmount = swapNacForUSDT(_usdtAmount,address(this));
        
        IERC20(usdt).approve(router, _usdtAmount);
        IERC20(nac).approve(router, _nacAmount);
            
        Router.addLiquidity(
            usdt,
            nac,
            _usdtAmount,
            _nacAmount,
            0, 
            0, 
            lpVault, 
            block.timestamp
        );
    }

    function withdrawAllUsdt(address _to)public onlyOwner{
        uint _banalce = IERC20(usdt).balanceOf(address(this));
        IERC20(usdt).transfer(_to,_banalce);
    }

    function getUserMessageHash(address _account,address _token,uint _claimAmount,uint _burnAmount,uint _expirationTime,uint _nonce) public virtual pure returns(bytes32){
        return keccak256(abi.encodePacked(_account,_token,_claimAmount, _burnAmount,_expirationTime,_nonce));
    }

    fallback() external payable {}
    receive() external payable {}

}
