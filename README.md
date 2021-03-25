# Exchange-Token-LINK
A smart contract to exchange ETH/DAI for LINK using 1inch smart contracts

## Flow
It uses the [OneSplitAudit.sol](https://github.com/1inch/1inchProtocol/blob/master/contracts/OneSplitAudit.sol) smart contract from https://github.com/1inch/1inchProtocol
 to swap its entire balance of ETH or DAI for LINK token.
 
 Steps:
  - Use a decentralized oracle at [chainlink](https://docs.chain.link/docs/get-the-latest-price) to get the fair conversion rate. 
  - Use the `getExpectedReturn` function in OneSplitAudit.sol to get the expected number of LINK tokens we can get
  - If the difference is greater than `_priceDifference`, don't initiate a swap
  - Use the `swap` function in OneSplitAudit.sol to initiate the swap
  
 ## Functions
 
  - `getOracleLatestPrice(address _priceFeed)`
  returns the latest price returned by the specified price-feed. Internally called by both the exchange functions
 
  - `exchangeBalanceDai(uint _priceDifference, uint _slippage)`
  exchanges its entire DAI balance for LINK
  
  - `exchangeBalanceEth(uint _priceDifference, uint _slippage)`
  exchanges its entire ETH balance for LINK

`_priceDifference` : max percentage difference tolerable between oracle value and expected-return value

`_slippage` : max percentage difference tolerable between expected-return value and actual swap value
