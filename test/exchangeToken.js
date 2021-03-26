const { BN, constants, expectEvent, expectRevert } = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const aggregatorV3InterfaceABI = [{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"description","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint80","name":"_roundId","type":"uint80"}],"name":"getRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}];
const priceFeed_LinkUsd = "0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c";
const priceFeed_LinkEth = "0xDC530D9457755926550b59e8ECcdaE7624181557";
const bn100 = new BN('100', 10);

const ExchangeToken = artifacts.require('ExchangeToken');
const priceFeedLinkUsd = new web3.eth.Contract(aggregatorV3InterfaceABI, priceFeed_LinkUsd);
const priceFeedLinkEth = new web3.eth.Contract(aggregatorV3InterfaceABI, priceFeed_LinkEth);

contract('ExchangeToken', () => {
	let exchangeToken = null;
	before(async () => {
		exchangeToken = await ExchangeToken.deployed();
	});

	it('Should deploy smart contract', async () => {
		assert(exchangeToken.address !== '');
	});

	it('Should fetch correct LINK/USD oracle data', async () => {
		const result = await exchangeToken.getOracleLatestPrice(priceFeed_LinkUsd);
		const expectedResult = await priceFeedLinkUsd.methods.latestRoundData().call();
		expect(result).to.be.bignumber.equals(expectedResult.answer);
	});

	it('Should fetch correct LINK/ETH oracle data', async () => {
		const result = await exchangeToken.getOracleLatestPrice(priceFeed_LinkEth);
		const expectedResult = await priceFeedLinkEth.methods.latestRoundData().call();
		expect(result).to.be.bignumber.equals(expectedResult.answer);
	});

	it('Should swap only if within acceptable price difference: 5%', async () => {

		const priceDifference = 5;
		const result = await exchangeToken.calculateDaiSwap(priceDifference, '100000000');

		let oracleExpectedLink = new BN(result.oracleExpectedLink.toString(), 10);
		let expectedLink = new BN(result.expected.toString(), 10);
		let withinBudget = result.withinBudget;		
		let actualWithinBudget = expectedLink.gte( oracleExpectedLink.mul(bn100.sub(new BN(priceDifference.toString(), 10))).div(bn100) );
		assert(withinBudget === actualWithinBudget);
	});


	it('Should swap only if within acceptable price difference: 0%', async () => {

		const priceDifference = 0;
		const result = await exchangeToken.calculateDaiSwap(priceDifference, '100000000');

		let oracleExpectedLink = new BN(result.oracleExpectedLink.toString(), 10);
		let expectedLink = new BN(result.expected.toString(), 10);
		let withinBudget = result.withinBudget;		
		let actualWithinBudget = expectedLink.gte( oracleExpectedLink.mul(bn100.sub(new BN(priceDifference.toString(), 10))).div(bn100) );
		assert(withinBudget === actualWithinBudget);
	});

	it('Should revert when slippage > 10', async function () {
		await expectRevert(exchangeToken.exchangeBalanceEth(5,11), 'slippage % can only be between 0 and 10');
	});

	it('Should revert when price difference > 10', async function () {
		await expectRevert(exchangeToken.exchangeBalanceEth(11,2), 'price difference % can only be between 0 and 10');
	});
});