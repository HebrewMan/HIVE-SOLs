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

contract ALEOX is ERC20, Ownable {

    address public tradeVault1 = 0x6c33A19369B9218d3Ab32C2d579BcE29739D82ab;
    address public tradeVault2 = 0x3CCa5dd770fc6702487129b2A84473b80AbC0CB8;
    address public tradeVault3 = 0xabcE06eA8B6B68Dd216b365f43bF8e3cE22e3BF2;


    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public mainPair;

    bool public switchAddLiquidity;

    mapping(address => bool) public whiteList;
    mapping(address => bool) private _swapPairList;//wbnb usdt 不能加池子
    mapping(address => bool) public lpHolderExist;

    address[] public lpHolders;

    uint tradeFee = 3;
    uint removeFee = 5;

    event SetManager(address manager, bool status);

    constructor() ERC20("ALEOX", "ALEOX") {
        _mint(msg.sender, 1000000000 * 10 ** 18);

        ISwapRouter swapRouter = ISwapRouter(router);
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        mainPair = swapFactory.createPair(address(this), usdt);
        _swapPairList[mainPair] = true;
    }

    function setTradeFee(uint _fee) external onlyOwner {
        tradeFee = _fee;
    }

    function setRemoveFee(uint _fee) external onlyOwner {
        removeFee = _fee;
    }

     function setVaults(address _addr1,address _addr2,address _addr3) external onlyOwner {
        tradeVault1 = _addr1;
        tradeVault1 = _addr2;
        tradeVault3 = _addr3;
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

    function setSwitchAddLiquidity( bool _status) external onlyOwner {
        switchAddLiquidity = _status;
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

        if(isAdd){
            require(switchAddLiquidity,"Switch is false");
            _addLpHolder(from);
        }

        if (!whiteList[from] && !whiteList[to]) {
            if (!isAdd) {
        
                if (_swapPairList[from] && !isRemove || _swapPairList[to]) { // Buy sell transaction
                
                    uint256 tradeFee1 = (amount * 10) / 1000; // 1% address
                    uint256 tradeFee2 = (amount * 10) / 1000; // 1% addr
                    uint256 tradeFee3 = (amount * 5) / 1000; // 0.5% addr
                    uint256 tradeFee4 = (amount * 5) / 1000; // 0.5% burn

                    super._transfer(from, tradeVault1, tradeFee1);
                    super._transfer(from, tradeVault2, tradeFee2);
                    super._transfer(from, tradeVault3, tradeFee3);
                    super._transfer(from, address(0xdead), tradeFee4);

                    amount = amount - tradeFee1 - tradeFee2 - tradeFee3 - tradeFee4;
                }
                if(isRemove){
                    _removeLpHolder(to);
                    uint256 fee = (amount * removeFee) / 100; // 1.5% to LP holders
                    super._transfer(from, address(this), fee);
                    if (lpHolders.length > 0) _distributeToLpHolders(fee);
                    amount = amount - fee;

                }
             
            }

        }

        super._transfer(from, to, amount * 99 / 100);

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
        }
    }

    function _removeLpHolder(address holder) private {
        if (lpHolderExist[holder] && IERC20(mainPair).balanceOf(holder) == 0) {
            for (uint256 i = 0; i < lpHolders.length; i++) {
                if (lpHolders[i] == holder) {
                    lpHolders[i] = lpHolders[lpHolders.length - 1];
                    lpHolders.pop();
                    lpHolderExist[holder] = false;
                    break;
                }
            }
        }
    }


    function _isAddLiquidity() internal view returns (bool isAdd) {
        ISwapPair MainPair = ISwapPair(mainPair);
        (uint112 r0, uint112 r1,) = MainPair.getReserves();

        address tokenOther = usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint256 bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        ISwapPair MainPair = ISwapPair(mainPair);
        (uint112 r0, uint112 r1,) = MainPair.getReserves();

        address tokenOther = usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint256 bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }
}
