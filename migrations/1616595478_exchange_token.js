const ExchangeToken = artifacts.require("ExchangeToken");

module.exports = function (deployer) {
  deployer.deploy(ExchangeToken);
};
