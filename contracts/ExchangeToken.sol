// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/OneSplitAudit.sol";

contract ExchangeToken {

    address internal priceFeed_LinkEth;
    address internal priceFeed_LinkUsd;

    address public onesplit;
    address public linkToken;
    address public daiToken;

    uint public constant daiDecimal = 8;
    uint public constant ethDecimal = 18;

    uint internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
    uint internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
    uint internal constant FLAG_DISABLE_BANCOR = 0x04;
    uint internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
    uint internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
    uint internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
    uint internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
    uint internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
    uint internal constant FLAG_DISABLE_OASIS = 0x08;
    uint internal constant FLAG_DISABLE_SHELL = 0x8000000000;

    uint internal constant FLAG_ENABLE_UNISWAP_ONLY = FLAG_DISABLE_ALL_WRAP_SOURCES + FLAG_DISABLE_BALANCER_ALL + FLAG_DISABLE_BANCOR + FLAG_DISABLE_CURVE_ALL + FLAG_DISABLE_DFORCE_SWAP + FLAG_DISABLE_KYBER_ALL + FLAG_DISABLE_MOONISWAP + FLAG_DISABLE_MSTABLE_MUSD + FLAG_DISABLE_OASIS + FLAG_DISABLE_SHELL;

    event SwapCancelled(string reason);

    constructor() {
        onesplit = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);
        linkToken = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        daiToken = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        priceFeed_LinkEth = address(0xDC530D9457755926550b59e8ECcdaE7624181557);
        priceFeed_LinkUsd = address(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
    }

    modifier checkBuffers(uint _priceDifference, uint _slippage) {
        require (_priceDifference <= 10, "price difference % can only be between 0 and 10");
        require (_slippage <= 10, "slippage % can only be between 0 and 10");
        _;
    }

    function getOracleLatestPrice(address _priceFeed) public view returns (uint) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_priceFeed).latestRoundData();
        return uint(price);
    }

    function calculateDaiSwap(uint _priceDifference, uint _fromBalance) public view returns (
        uint oracleExpectedLink,
        uint expected,
        uint256[] memory distribution,
        bool withinBudget) {

        oracleExpectedLink = (_fromBalance * 10 ** daiDecimal) / getOracleLatestPrice(priceFeed_LinkUsd);
        (expected, distribution) = OneSplitAudit(onesplit).getExpectedReturn(daiToken, linkToken, _fromBalance, 100, FLAG_ENABLE_UNISWAP_ONLY);

        withinBudget = (expected >= (oracleExpectedLink * (100 - _priceDifference))/100 );
        return (oracleExpectedLink, expected, distribution, withinBudget);
    }

    function exchangeBalanceDai(uint _priceDifference, uint _slippage) checkBuffers(_priceDifference, _slippage) external {
        uint fromBalance = IERC20(daiToken).balanceOf(address(this));
        uint expected;
        uint[] memory distribution;
        bool withinBudget;

        (, expected, distribution, withinBudget) = calculateDaiSwap(_priceDifference, fromBalance);

        if (!withinBudget) {
            emit SwapCancelled("Expected return less than Price Feed quantity");
            return;
        }
        uint minReturn = (expected * (100 - _slippage))/100;

        IERC20(daiToken).approve(onesplit, fromBalance);
        OneSplitAudit(onesplit).swap(daiToken, linkToken, fromBalance, minReturn, distribution, FLAG_ENABLE_UNISWAP_ONLY);
    }

    function calculateEthSwap(uint _priceDifference, uint _fromBalance) public view returns (
        uint oracleExpectedLink,
        uint expected,
        uint256[] memory distribution,
        bool withinBudget) {

        oracleExpectedLink = (_fromBalance * 10 ** ethDecimal) / getOracleLatestPrice(priceFeed_LinkEth);
        (expected, distribution) = OneSplitAudit(onesplit).getExpectedReturn(address(0), linkToken, _fromBalance, 100, FLAG_ENABLE_UNISWAP_ONLY);

        withinBudget = (expected >= (oracleExpectedLink * (100 - _priceDifference))/100 );
        return (oracleExpectedLink, expected, distribution, withinBudget);
    }

    function exchangeBalanceEth(uint _priceDifference, uint _slippage) checkBuffers(_priceDifference, _slippage) external {
        uint fromBalance = address(this).balance;
        uint expected;
        uint[] memory distribution;
        bool withinBudget;

        (, expected, distribution, withinBudget) = calculateEthSwap(_priceDifference, fromBalance);

        if (!withinBudget) {
            emit SwapCancelled("Expected return less than Price Feed quantity");
            return;
        }

        uint minReturn = (expected * (100 - _slippage))/100;
        OneSplitAudit(onesplit).swap{value:fromBalance}(address(0), linkToken, fromBalance, minReturn, distribution, FLAG_ENABLE_UNISWAP_ONLY);
    }

    receive() external payable {
    }

    function depositEther() external payable {
    }

    function balanceOf() external view returns (uint) {
        return address(this).balance;
    }
}