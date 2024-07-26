// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SignTool.sol";

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

contract ICO1 is Ownable,SignTool{

    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public nac = 0x363d624545c33F032cE35FFD0Ab952F06084b0f9;
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;//v2 
    address public dead =  address(0xdead);
    address public lpVault = 0x6128f989381CA384EAE04045F03A472D0F501b2C;

    address public nacVault = 0x43121D00CF83CD804af33093153C5C159A1f87dF;
    address public vaultClaim = 0x49D9EA042bAd845c2552554e1Fd7D22deb76F5D5;
    address public vault5 = 0xA5E525b4E8A06FF23f83d81119e5E7F6DD43e3bb;
 
    mapping(address => uint8) public userTimes;
 
    IUniswapV2Router01 public Router = IUniswapV2Router01(router);

    function getPaths() public  view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = nac;
        return path;
    }

    function getNACAmountForUSDT(uint _amount) public view returns (uint256) {
        uint256 amountIn = _amount * 10 ** 18;

        uint256[] memory amountsOut = Router.getAmountsOut(amountIn, getPaths());
        return amountsOut[1];
    }

    function setNacAddr(address _addr)external onlyOwner{
        nac = _addr;
    }

    function setNacClaim(address _addr)external onlyOwner{
        vaultClaim = _addr;
    }

    function mintNAC(address _addr10, address _addr5, address _token,uint _amount,uint _endTime,uint _nonce,bytes calldata _signature) external {
        require(userNonce[msg.sender] == _nonce,"Nonce: Nonce error");
        require(block.timestamp <= _endTime,"Time:The signature has expired.");
        require(userTimes[msg.sender]<=5,"time more than 5.");

        userTimes[msg.sender]++;
        userNonce[msg.sender]++;

        uint _usdtToNacRatio = getNACAmountForUSDT(1);
        //to claim
        IERC20(nac).transferFrom(nacVault,vaultClaim,_usdtToNacRatio * 2);
        //to dapp
        IERC20(nac).transferFrom(nacVault,vaultClaim,_usdtToNacRatio * 40);
        //to invite rewards
        uint _rewards10 = _usdtToNacRatio * 60 * 10 / 100;
        IERC20(nac).transferFrom(nacVault,_addr10,_rewards10);

        uint _rewards5 = _usdtToNacRatio * 60 * 5 / 100;
        IERC20(nac).transferFrom(nacVault,_addr5,_rewards5);
        //to user
        IERC20(nac).transferFrom(nacVault,msg.sender,_usdtToNacRatio * 20);

        bytes32 _msgHash = getUserMessageHash(msg.sender,_addr10,_addr5,_token, _amount,_endTime,_nonce);
        require(verify(_msgHash, _signature), "Signature: Error signature.");

        IERC20(usdt).transferFrom(msg.sender, address(this), 100 * 10 ** 18);

        //10% USDT 10% NAC to be LP then LP to 0xdead
        _addLiquidity(10 * 10 ** 18);
        //5% swap and to 0xdead
        _swapNacForUSDT(5 * 10 ** 18,dead);
        //5% to ecoVault
        IERC20(usdt).transfer(vault5, 5 * 10 ** 18);
        //70 to claim
        IERC20(usdt).transfer(vaultClaim, 70 * 10 ** 18);

    }

    function _swapNacForUSDT(uint _usdtAmount, address _to) private returns (uint nacAmount) {
        IERC20(usdt).approve(router, _usdtAmount * 10000);

        uint256[] memory amountsOut = Router.getAmountsOut(_usdtAmount, getPaths());

        uint[] memory amounts = Router.swapExactTokensForTokens(
            _usdtAmount,
            amountsOut[1],
            getPaths(),
            _to,
            block.timestamp + 10
        );

        nacAmount = amounts[1];
    }


    function _addLiquidity(uint256 _usdtAmount) private {
        uint _nacAmount = _swapNacForUSDT(_usdtAmount,address(this));
        
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


    function setRouter(address _addr)external onlyOwner{
        router = _addr;
    }

    function withdraw(address _erc20,address _to,uint _amount)public onlyOwner{
        IERC20(_erc20).transfer(_to,_amount);
    }

    function withdraw(address _to,uint _amount)public onlyOwner{
        (bool sent,) = payable(_to).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getUserMessageHash(address _account,address _addr10,address _addr5,address _token,uint _amount,uint _expirationTime,uint _nonce) public virtual pure returns(bytes32){
        return keccak256(abi.encodePacked(_account,_addr10,_addr5,_token,_amount,_expirationTime,_nonce));
    }

    fallback() external payable {}
    receive() external payable {}

}