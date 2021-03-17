const { info } = require("../io/logger");
const Gifcli = require("@etherisc/gifcli");

const test = async () => {
  const gif = await Gifcli.connect();
  info("Connected!");

  const productServiceDeployed = await gif.artifact.get('FlightDelaySokol', 'development', 'FlightDelayEtheriscOracle');

  info(JSON.stringify(productServiceDeployed).slice(0, 40));
};

test();
