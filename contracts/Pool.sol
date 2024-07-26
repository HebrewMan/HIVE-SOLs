// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
// import "@aave/incentives-controller/contracts/interfaces/IStakedAave.sol";
contract HivePool {
    IPoolAddressesProvider public addressesProvider;

    address[] private _reservesList;

    IPool public lendingPool;
    IERC20 public usdt;
    IERC20 public underlyingAsset;
    // IStakedAave public stakedAave;

    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userDebts;

    mapping(address => mapping (address => uint256)) private _userBalances;


    // struct Supplies{
    //     address[] assets;
    //     uint256[] amounts;
    //     uint256[] interestRateModes;
    //     bool[] isCollaterals; 
    // }
    //用户池子的 和平台池子的

    //资产列表 =》 资产类型、存入量、借出量、利用率、借款利率、存款利率、清算阈值、是否支持、是否冻结、
    //用户supplys总池数据 =》总存入价值、 总存款利率apy、总抵押物价值
    //用户supply单池数据 =》存入资产类型、存入资产数量、存款利率apy、是否成为抵押物、supply、withdaraw

    //用户borrows总池数据 =》债务类型、债务数量、借款利率、borrow、repay

    //总存款利率 = (A存款价值*A年化收益 + B存款价值*B年华收益) / 总存款

    //总借款利率 = (A债务价值*A年化收益 + B债务价值*B年华收益) / 总债务

    //总收益 = A存款价值*A存款利率 + B存款价值*B存款利率 4158+4218=8376

    //总债务 = A债务价值*A借款利率 + B债务价值*B借款利率 1158.3+796.7=1955

    // 8376-1955=6421
    // 6421/36000=0.1783611111
    //net year apy =（总收益 - 总债务 ）/ （总存款 - 总债务）

    //健康分子 = (A抵押物价值*A清算阈值 + B抵押物价值*B清算阈值) / 总债务
   
    struct ReserveData {
        uint256 availableLiquidity;//可借出的数量
        uint256 liquidityIndex;//id 
        uint256 liquidityRate;//流动性占比
        address assetAddress;//资产地址
        uint256 totalSupplied;//总供应
        uint256 totalborrowed;//总借出
        uint8 supplyApy;
        uint8 borrowApy;
        uint8 ltv; // Loan-to-Value 最大借出
        uint8 liquidationThreshold; // 清算阈值
    }

    //一个资产一个池子 对应不同的利率流动性指数

    mapping(address => ReserveData) public reservesData;

   

    struct Supply {
        address underlyingAsset;
        uint256 aaveAmount;
        uint256 hiveAmount;
        uint256 maxFromAaveWithdrawAmount;
        uint256 apy;
    }

    struct Borrow {
        uint256 amount;
        uint256 apy;
    }

    mapping(address => Supply[]) public userSupplies;
    
    mapping(address => Borrow[]) public userBorrows;

    constructor(address _addressesProvider, address _usdt, address _stakedAave) {
        addressesProvider = IPoolAddressesProvider(_addressesProvider);
        lendingPool = IPool(addressesProvider.getPool());
        usdt = IERC20(_usdt);
        // stakedAave = IStakedAave(_stakedAave);
    }

    function supply(address asset, uint256 amount) external {
        //判断是否土狗 aave 不支持土狗
        //记录用户份额计算用户收益
        require(amount > 0, "Amount must be greater than zero");

        userSupplies[msg.sender].push({});

        IERC20(asset).transferFrom(msg.sender, address(this), amount);


        _userBalances[msg.sender][address(underlyingAsset)] += amount;
        underlyingAsset.approve(address(lendingPool), amount);
        lendingPool.supply(address(underlyingAsset), amount, address(this), 0);
    }

    // function claimAaveRewards(address user) external {
    //     stakedAave.claimRewards(user, type(uint256).max);
    // }

    function claimInterest(address user) external {
        // 实现领取利息逻辑
    }

    function withdrawAll(address user) external {
        uint256 amount = userBalances[user];
        lendingPool.withdraw(address(usdt), amount, user);
        userBalances[user] = 0;
    }

    function repay(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.approve(address(lendingPool), amount);
        lendingPool.repay(address(usdt), amount, 2, address(this)); // 2: Variable interest rate mode
        userDebts[msg.sender] -= amount;
    }

    function redeemCollateral(uint256 amount) external {
        // 实现赎回抵押物逻辑
    }

    function liquidateCall(address user) external {
        // 实现清算逻辑
    }

    function getUserAaveDeposit(address user) external view returns (uint256) {
        // 实现获取用户 AAVE 存款逻辑
    }

    function getUserAaveRewards(address user) external view returns (uint256) {
        // 实现获取用户 AAVE 收益逻辑
    }

    function getUserLoanAmount(address user) external view returns (uint256) {
        return userDebts[user];
    }

    function getUserLoanInterest(address user) external view returns (uint256) {
        // 实现获取用户贷出利息收益逻辑
    }

    function getUserTotalDeposit(address user) external view returns (uint256) {
        return userBalances[user];
    }

    function getUserUtilizationRate(address user) external view returns (uint256) {
        // 实现获取用户资金利用率逻辑
    }

    // function getPoolTotalLiquidity() external view returns (uint256) {
    //     return lendingPool.getReserveData(address(usdt)).availableLiquidity;
    // }

    function getPoolUtilizationRate() external view returns (uint256) {
        // 实现获取资金池利用率逻辑
    }

    function getBorrowerInterest(address user) external view returns (uint256) {
        // 实现获取借款人利息逻辑
    }

    function getBorrowerCollateral(address user) external view returns (uint256) {
        // 实现获取借款人抵押物逻辑
    }

    function getHealthFactor(address user) external view returns (uint256) {
        // 实现获取用户健康因子逻辑
    }

    function getLiquidationPenalty(address user) external view returns (uint256) {
        // 实现获取用户清算扣款逻辑
    }

    function getLiquidationThreshold(address user) external view returns (uint256) {
        // 实现获取用户清算线逻辑
    }

    function getCollateralPrice(address collateral) external view returns (uint256) {
        // 实现获取抵押物价格逻辑
    }

    function getLTV(address user) external view returns (uint256) {
        // 实现获取用户质押率逻辑
    }
}
