// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IAaveOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HivePool is Ownable {

    IPoolAddressesProvider public provider;
    IAaveOracle public priceOracle;
    IPool public lendingPool;

    address[] private _reservesList;
    address[] private _borrowList;
    address[] private _supplyList;

    struct ReserveData {
        bool isCanBeCollateral;
        uint reserveSize;
        uint availableLiquidity;
        uint utilizationRate;
        uint oraclePrice;
        uint ltv; // Loan-to-Value 最大借出
        uint liquidationThreshold; // 清算阈值
        uint supplyApy;
        uint borrowApy;
        uint totalSupplied;
        uint totalBorrowed;
        uint totalLiquidated;
    }

    struct Balance {
        address asset;
        uint256 amount;
        uint256 time;
    }

    struct SupplyItem {
        address asset;
        uint256 walletBalance;
        uint256 walletBalanceValue;
        uint256 supplyApy;
    }

    struct BorrowItem {
        address asset;
        uint256 debt;
        uint256 debtValue;
        uint256 borrowApy;
    }

    mapping(address => ReserveData) public reservesData;
    mapping(address => Balance) private _userBalances;
    mapping(address => uint256) public userDebts;
    mapping(address => mapping(address => uint256)) private _userSupplies; // 用户供应的资产和数量
    mapping(address => mapping(address => uint256)) private _userBorrowings; // 用户借款的资产和数量

    event Supply(address indexed user, address indexed asset, uint256 amount);
    event Borrow(address indexed user, address indexed asset, uint256 amount);
    event Repay(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Liquidation(address indexed user, address indexed collateralAsset, address indexed debtAsset, uint256 debtToCover, uint256 liquidationPrice);


    constructor(address _addressesProvider, address _priceOracle) {
        provider = IPoolAddressesProvider(_addressesProvider);
        lendingPool = IPool(provider.getPool());
        priceOracle = IAaveOracle(_priceOracle);
    }

    function addReserve(address _asset, ReserveData memory _reserveData) external onlyOwner {
        reservesData[_asset] = _reserveData;
        _reservesList.push(_asset);
    }

    function addBorrowList(address _asset) external onlyOwner {
        _borrowList.push(_asset);
    }

    function addSupplyList(address _asset) external onlyOwner {
        _supplyList.push(_asset);
    }

    function supply(address _asset, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");

        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        IERC20(_asset).approve(address(lendingPool), _amount);
        lendingPool.supply(_asset, _amount, address(this), 0);

        Balance storage userBalance = _userBalances[msg.sender];
        userBalance.asset = _asset;
        userBalance.amount += _amount;
        userBalance.time = block.timestamp;

        Balance storage contractBalance = _userBalances[address(this)];
        contractBalance.asset = _asset;
        contractBalance.amount += _amount;
        contractBalance.time = block.timestamp;

        _userSupplies[msg.sender][_asset] += _amount; // 更新用户供应的资产

        emit Supply(msg.sender,_asset,_amount);
    }

    function withdraw(address _asset, uint256 _amount) external {
        Balance storage userBalance = _userBalances[msg.sender];
        require(userBalance.amount >= _amount, "Insufficient balance");

        lendingPool.withdraw(_asset, _amount, msg.sender);

        userBalance.amount -= _amount;

        Balance storage contractBalance = _userBalances[address(this)];
        contractBalance.amount -= _amount;

        _userBorrowings[msg.sender][_asset] += _amount; // 更新用户借款的资产

        emit Withdraw(msg.sender,_asset,_amount);
    }

    function borrow(address _asset, uint256 _amount) external {
        uint256 maxBorrow = getUserMaxBorrow(msg.sender);
        require(_amount <= maxBorrow, "Amount exceeds max borrow limit");

        lendingPool.withdraw(_asset, _amount, address(this));
        IERC20(_asset).transfer(msg.sender, _amount);

        userDebts[msg.sender] += _amount;

        emit Borrow(msg.sender,_asset,_amount);
    }

    function repay(address _asset, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        userDebts[msg.sender] -= _amount;

        emit Repay(msg.sender,_asset,_amount);
    }

     function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover
    ) external {
        uint256 userDebt = userDebts[user];
        require(userDebt >= debtToCover, "Debt to cover exceeds user's debt");

        uint256 healthFactor = calculateHealthFactor(user);
        require(healthFactor < 1e18, "Health factor must be less than 1 for liquidation");

        uint256 collateralValue = calculateCollateralValue(user, collateralAsset);
        uint256 liquidationThreshold = reservesData[collateralAsset].liquidationThreshold;
        require(collateralValue < (userDebt * liquidationThreshold) / 10000, "Collateral value must be below the liquidation threshold");

        IERC20(debtAsset).transferFrom(msg.sender, address(this), debtToCover);

        userDebts[user] -= debtToCover;

        uint256 collateralAmount = calculateCollateralAmount(collateralAsset, debtToCover);
        IERC20(collateralAsset).transfer(msg.sender, collateralAmount);

        // 更新合约中抵押品的状态
        reservesData[collateralAsset].totalBorrowed -= debtToCover;
        reservesData[collateralAsset].availableLiquidity += collateralAmount;
        reservesData[collateralAsset].totalLiquidated += debtToCover;
    }

    function calculateHealthFactor(address user) internal view returns (uint256) {
        //计算健康因子
        uint256 totalCollateralValue = 0;
        uint256 totalDebtValue = userDebts[user];

        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 price = priceOracle.getAssetPrice(asset);
            uint256 collateralValue = _userBalances[user].amount * price;
            totalCollateralValue += collateralValue * reservesData[asset].ltv / 10000;
        }

        if (totalDebtValue == 0) {
            return type(uint256).max;
        }

        return (totalCollateralValue * 1e18) / totalDebtValue;
    }

    function calculateCollateralValue(address user, address asset) internal view returns (uint256) {
        //计算清算阈值
        uint256 price = priceOracle.getAssetPrice(asset);
        return _userBalances[user].amount * price;
    }

    function calculateCollateralAmount(address collateralAsset, uint256 debtToCover) internal view returns (uint256) {
        // 计算需要的抵押品数量
        uint256 price = priceOracle.getAssetPrice(collateralAsset);
        return (debtToCover * 1e18) / price; 
    }

    function getUserMaxBorrow(address _user) public view returns (uint256) {
        // 返回用户最大可借出多少美元 ===》 所有抵押物的价值 * 所有抵押物资产的平均ltv
        uint256 totalCollateralValue = 0;
        uint256 totalLtv = 0;
        uint256 collateralCount = 0;

        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 price = priceOracle.getAssetPrice(asset);
            uint256 collateralValue = _userBalances[_user].amount * price;

            if (collateralValue > 0) {
                totalCollateralValue += collateralValue;
                totalLtv += reservesData[asset].ltv;
                collateralCount++;
            }
        }

        if (collateralCount == 0) {
            return 0;
        }


        uint256 averageLtv = totalLtv / collateralCount;

        return (totalCollateralValue * averageLtv) / 10000; // assuming LTV is in basis points
    }

    function getMarketData() external view returns (uint256 totalMarketSize, uint256 totalAvailable, uint256 totalBorrows) {
    
        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 price = priceOracle.getAssetPrice(asset);
            totalMarketSize += reservesData[asset].totalSupplied * price;
            totalAvailable += reservesData[asset].availableLiquidity * price;
            totalBorrows += reservesData[asset].totalBorrowed * price;
        }
    }

    function getLiquidationData() external view returns (uint256 tvl, uint256 liquidated, uint256 collateralRatio) {
        // 返回整体市场的 tvl liquidated collateralRato
        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 price = priceOracle.getAssetPrice(asset);
            tvl += reservesData[asset].totalSupplied * price;
            liquidated += reservesData[asset].totalLiquidated * price;
            collateralRatio += (reservesData[asset].totalSupplied * reservesData[asset].ltv) / 10000;
        }
        collateralRatio = (collateralRatio * 1e18) / tvl; // Assuming collateral ratio is a percentage
    }

    function getLiquidationList() external view returns (address[] memory) {
        // 获取当前可清算的用户列表
        // This is a placeholder and would need additional logic to determine which users are liquidatable
        return _reservesList;
    }

    function getDashboardData(address _user) external view returns (uint256 netWorth, uint256 netApy, uint256 healthFactor) {
        // netWorth = （总供应价值-债务）
        // netApy = （总收益 - 总债务 ）/ （总存款 - 总债务）
        // healthFactor =  (A抵押物价值*A清算阈值 + B抵押物价值*B清算阈值) / 总债务

        uint256 totalSuppliedValue = 0;
        uint256 totalBorrowedValue = userDebts[_user];
        uint256 totalCollateralValue = 0;
        uint256 totalSupplyApy = 0;
        uint256 totalDebtApy = 0;

        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 price = priceOracle.getAssetPrice(asset);
            uint256 supplied = _userBalances[_user].amount * price;
            totalSuppliedValue += supplied;
            totalCollateralValue += supplied * reservesData[asset].liquidationThreshold / 10000;
            totalSupplyApy += supplied * reservesData[asset].supplyApy;
        }

        netWorth = totalSuppliedValue - totalBorrowedValue;
        netApy = (totalSupplyApy - totalDebtApy) / (totalSuppliedValue - totalBorrowedValue);
        healthFactor = (totalCollateralValue * 1e18) / totalBorrowedValue;
    }

    function getUserBorrowData(address _user) external view returns (uint256 balance, uint256 apy, uint256 borrowPowerUsed) {
        // balance 总债务价值 A债务价值*A借款利率 + B债务价值*B借款利率
        // 总借款利率 apy = (A债务价值*A年化收益 + B债务价值*B年华收益) / 总债务
        // Borrow power used = 当前借款/最大可借 (所有抵押物平均ltv X 抵押物总价值)

        balance = userDebts[_user];
        uint256 totalDebtApy = 0;
        uint256 totalCollateralValue = 0;
        uint256 averageLtv = 0;

        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 price = priceOracle.getAssetPrice(asset);
            uint256 debtValue = reservesData[asset].totalBorrowed * price;
            totalDebtApy += debtValue * reservesData[asset].borrowApy;
            totalCollateralValue += debtValue;
            averageLtv += reservesData[asset].ltv;
        }

        averageLtv = averageLtv / _reservesList.length;
        apy = totalDebtApy / balance;
        borrowPowerUsed = (balance * 1e18) / ((totalCollateralValue * averageLtv) / 10000);
    }

    function getUserSuppliesData(address _user) external view returns (uint256 balance, uint256 apy, uint256 collateral) {
        // balance 总收益 = A存款价值*A存款利率 + B存款价值*B存款利率
        // apy 总存款利率 = (A存款价值*A年化收益 + B存款价值*B年华收益) / 总存款
        // collateral = 所有抵押物的数量 * 该抵押物价格

        balance = 0;
        apy = 0;
        collateral = 0;
        uint256 totalSuppliedValue = 0;
        uint256 totalSupplyApy = 0;

        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 price = priceOracle.getAssetPrice(asset);
            uint256 supplied = _userBalances[_user].amount * price;
            totalSuppliedValue += supplied;
            totalSupplyApy += supplied * reservesData[asset].supplyApy;
        }

        balance = totalSuppliedValue;
        apy = totalSupplyApy / totalSuppliedValue;
        collateral = totalSuppliedValue;
    }

   function getSupplyList() external view returns (SupplyItem[] memory) {
        // 返回整个市场支持供应的资产列表
        SupplyItem[] memory supplyList = new SupplyItem[](_supplyList.length);
        for (uint256 i = 0; i < _supplyList.length; i++) {
            address asset = _supplyList[i];
            uint256 balance = IERC20(asset).balanceOf(address(this));
            uint256 price = priceOracle.getAssetPrice(asset);
            uint256 balanceValue = balance * price;
            uint256 supplyApy = reservesData[asset].supplyApy;

            supplyList[i] = SupplyItem({
                asset: asset,
                walletBalance: balance,
                walletBalanceValue: balanceValue,
                supplyApy: supplyApy
            });
        }
        return supplyList;
    }

    function getBorrowList() external view returns (BorrowItem[] memory) {
        // 返回整个市场支持借款的资产列表
        BorrowItem[] memory borrowList = new BorrowItem[](_borrowList.length);
        for (uint256 i = 0; i < _borrowList.length; i++) {
            address asset = _borrowList[i];
            uint256 balance = IERC20(asset).balanceOf(address(this));
            uint256 price = priceOracle.getAssetPrice(asset);
            uint256 balanceValue = balance * price;
            uint256 borrowApy = reservesData[asset].borrowApy;

            borrowList[i] = BorrowItem({
                asset: asset,
                debt: balance,
                debtValue: balanceValue,
                borrowApy: borrowApy
            });
        }
        return borrowList;
    }

    function getUserSupplyList(address _user) external view returns (SupplyItem[] memory) {
        uint256 itemCount = 0;
        for (uint256 i = 0; i < _reservesList.length; i++) {
            if (_userSupplies[_user][_reservesList[i]] > 0) {
                itemCount++;
            }
        }

        SupplyItem[] memory supplyList = new SupplyItem[](itemCount);
        uint256 index = 0;

        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            uint256 balance = _userSupplies[_user][asset];
            if (balance > 0) {
                uint256 price = priceOracle.getAssetPrice(asset);
                uint256 balanceValue = balance * price;
                uint256 supplyApy = reservesData[asset].supplyApy;

                supplyList[index] = SupplyItem({
                    asset: asset,
                    walletBalance: balance,
                    walletBalanceValue: balanceValue,
                    supplyApy: supplyApy
                });
                index++;
            }
        }
        return supplyList;
    }

    function getUserBorrowingList(address _user) external view returns (BorrowItem[] memory) {
       
        uint256 itemCount = 0;
        for (uint256 i = 0; i < _borrowList.length; i++) {
            if (_userBorrowings[_user][_borrowList[i]] > 0) {
                itemCount++;
            }
        }

        BorrowItem[] memory borrowList = new BorrowItem[](itemCount);
        uint256 index = 0;

        for (uint256 i = 0; i < _borrowList.length; i++) {
            address asset = _borrowList[i];
            uint256 balance = _userBorrowings[_user][asset];
            if (balance > 0) {
                uint256 price = priceOracle.getAssetPrice(asset);
                uint256 balanceValue = balance * price;
                uint256 borrowApy = reservesData[asset].borrowApy;

                borrowList[index] = BorrowItem({
                    asset: asset,
                    debt: balance,
                    debtValue: balanceValue,
                    borrowApy: borrowApy
                });
                index++;
            }
        }
        return borrowList;
    }

    function getReserveData(address _asset) external view returns (ReserveData memory) {
        return reservesData[_asset];
    }
}
