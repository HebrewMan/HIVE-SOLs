// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ISwapRouter {
    function factory() external pure returns (address);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract COPYNAC is ERC20, Ownable {

    address public ecoValutAddr = address(0xB6fF144236232634cc4C3B10522b77d911eDC688);
    address public nftVaultAddr = 0x3526Cad62283B698ED2dC398dD0f9d4a2F0798c0;
    address public lpVaultAddr = address(0xdead);
    address public router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public usdt = 0x4128a6b222F4d37C66fe4f8AEcaf2c79467C08EE;
    address public mainPair;
    
    mapping(address => bool) public whiteList;
    mapping(address => bool) public lpHolderExist;
    mapping(address => bool) private _swapPairList;

    address[] public lpHolders;

    bool public isAllowBuy;

    event SetManager(address manager, bool status);

    constructor() ERC20("NAD", "NAD10") {
        _mint(msg.sender, 600000000 * 10 ** 18);

        ISwapRouter swapRouter = ISwapRouter(router);
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        mainPair = swapFactory.createPair(address(this), usdt);
        _swapPairList[mainPair] = true;
        whiteList[ecoValutAddr] = true;
        whiteList[address(0xdead)] = true;
        _transfer(msg.sender, ecoValutAddr, 550000000*10**18);
    }

    function batchSetWhiteList(address[] calldata _addresses, bool _status) external onlyOwner {
        for (uint256 i; i < _addresses.length; ++i) {
            whiteList[_addresses[i]] = _status;
        }
    }

    function setWhiteStatus(address _address, bool _status) external onlyOwner {
        whiteList[_address] = _status;
    }

    function setSwapPairStatus(address _address, bool _status) external onlyOwner {
        _swapPairList[_address] = _status;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        bool isAdd;
        bool isRemove;

        if (_swapPairList[to]) {
            isAdd = _isAddLiquidity();
        } 

        if (_swapPairList[from]) {
            isRemove = _isRemoveLiquidity();
        }

        if( !isAdd && !isRemove){

     
            // if (!_swapPairList[to] && !isAllowBuy && !whiteList[to] && !whiteList[from]) {
            //     revert("Buying is not allowed.");
            // }

             // 检查是否为普通用户与用户之间的转账
            bool isUserToUserTransfer = !_swapPairList[to] && !_swapPairList[from];

            // 如果不是普通用户与用户之间的转账，并且不允许购买，触发报错
            if (!isUserToUserTransfer && !isAllowBuy && !whiteList[to] && !whiteList[from]) {
                revert("Buying is not allowed.");
            }

        }

        if(isAdd){
            _addLpHolder(from);
        }

        if(!whiteList[from] && !whiteList[to]){
        
            if(!isAdd){

                uint256 distributionToLp = (amount * 15) / 1000; // 1.5% to LP holders
                uint256 distributionToEco = (amount * 5) / 1000; // 0.5% to eco vault
                uint256 distributionToNft = (amount * 16) / 1000; // 1.6% to NFT vault

                super._transfer(from, address(this), distributionToLp);
                super._transfer(from, ecoValutAddr, distributionToEco);
                super._transfer(from, nftVaultAddr, distributionToNft);

                if(lpHolders.length>0)_distributeToLpHolders(distributionToLp);
            
                amount = amount - distributionToLp - distributionToEco - distributionToNft;
            }
        }

        super._transfer(from, to, amount);

        if (isRemove) {
            _removeLpHolder(to);
        }

    }

    function _distributeToLpHolders(uint256 amount) private {
        uint256 totalSupply = IERC20(mainPair).totalSupply();

        for (uint256 i = 0; i < lpHolders.length; i++) {
            address holder = lpHolders[i];
            uint256 balance = IERC20(mainPair).balanceOf(holder);
            uint256 share = (balance * amount) / totalSupply;
            
            if (share > 0) {
                super._transfer(address(this), holder, share);
            }
        }
    }

    function _addLpHolder(address holder) private {
        if (!lpHolderExist[holder]) {
            lpHolders.push(holder);
            lpHolderExist[holder] = true;
            // whiteList[holder] = true;
        }
    }

    function _removeLpHolder(address holder) private {
        if (lpHolderExist[holder] && IERC20(mainPair).balanceOf(holder) == 0) {
            for (uint256 i = 0; i < lpHolders.length; i++) {
                if (lpHolders[i] == holder) {
                    lpHolders[i] = lpHolders[lpHolders.length - 1];
                    lpHolders.pop();
                    lpHolderExist[holder] = false;
                    // whiteList[holder] = false;
                    break;
                }
            }
        }
    }


      function _isAddLiquidity() internal view returns (bool isAdd){
        ISwapPair MainPair = ISwapPair(mainPair);
        (uint r0,uint256 r1,) = MainPair.getReserves();

        address tokenOther = usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair MainPair = ISwapPair(mainPair);
        (uint r0,uint256 r1,) = MainPair.getReserves();

        address tokenOther = usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    
}
