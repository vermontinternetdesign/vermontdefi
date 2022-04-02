const CoveredCalls = artifacts.require("CoveredCalls");

module.exports = function (deployer) {
  deployer.deploy(CoveredCalls);
};