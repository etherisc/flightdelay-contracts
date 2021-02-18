const { info } = require("../io/logger");
const Gifcli = require("@etherisc/gifcli");
const hre = require("hardhat");

async function main() {
  const gif = await Gifcli.connect();

  const productServiceDeployed = await gif.artifact.get(
    "platform",
    "development",
    "ProductService"
  );

  const FlightDelayEtheriscOracle = await hre.ethers.getContractFactory(
    "FlightDelayMockup"
  );

  if (!process.env.DRYRUN) {
    info(
      `Deploying FlightDelayEtheriscOracle, ProductService=${productServiceDeployed.address}`
    );
    const FD = await FlightDelayEtheriscOracle.deploy(
      productServiceDeployed.address,
      { gas: 3500000 }
    );

    await FD.deployed();
    const productId = (await FD.productId.call()).toNumber();
    info(`Product deployed; productId = ${productId}`);
    info("Sending artifacts: ");
  } else {
    info(`Dry Run: productService = ${productServiceDeployed.address}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
