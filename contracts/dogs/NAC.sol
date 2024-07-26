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

contract NAC is ERC20, Ownable {

    address public nacVault = 0x43121D00CF83CD804af33093153C5C159A1f87dF;
    address public nftVault = 0x26eD8c80d9b1F8481e7F36271FD24b8a07499Db4;

    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public mainPair;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public lpHolderExist;
    mapping(address => bool) private _swapPairList;

    uint256 public buyFee = 1000;//100%
    uint256 public sellFee = 36;

    address[] public lpHolders;

    event SetManager(address manager, bool status);

    constructor() ERC20("NAC Token", "NAC") {
        _mint(address(0x395FB952c86a61Ab0e5955C16d704A856139229E), 20000000 * 10 ** 18);
        _mint(address(0xa16Dc98D6f32c1aFBa09F56EfD63d07d71D4f7f3), 50000000 * 10 ** 18);
        _mint(nacVault, 530000000 * 10 ** 18);
        ISwapRouter swapRouter = ISwapRouter(router);
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        mainPair = swapFactory.createPair(address(this), usdt);
        _swapPairList[mainPair] = true;
        whiteList[nacVault] = true;
        whiteList[address(0xdead)] = true;
    }

    function setBuyFee(uint _fee) external onlyOwner {
        buyFee = _fee * 10;
    }

    function setNftVaultAddr(address _addr) external onlyOwner {
        nftVault = _addr;
    }

    function setNacVaultAddr(address _addr) external onlyOwner {
        nacVault = _addr;
    }

    function setSellFee(uint _fee) external onlyOwner {
        sellFee = _fee;
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

        if (isAdd) {
            _addLpHolder(from);
        }

        if (!whiteList[from] && !whiteList[to]) {
            if (!isAdd) {
        
                if (_swapPairList[from] && !isRemove) { // Buy transaction

                    amount = amount - (amount * buyFee) / 1000;

                }else if (_swapPairList[to] || isRemove){
                  
                    uint256 distributionToLp = (amount * 15) / 1000;
                    uint256 distributionToEco = (amount * 5) / 1000;
                    uint256 distributionToNft = (amount * 16) / 1000;

                    super._transfer(from, address(this), distributionToLp);
                    super._transfer(from, nacVault, distributionToEco);
                    super._transfer(from, nftVault, distributionToNft);

                    if (lpHolders.length > 0) _distributeToLpHolders(distributionToLp);

                    amount = amount - distributionToLp - distributionToEco - distributionToNft;
                } 
             
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
