const { expect } = require("chai");
const dipTokenAbi = require("../abis/dip.json");
const NETWORK = "localhost";

describe("FlightDelayStaking", function() {
  let flightDelayStaking;
  let dipToken;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  let httpProvider;

  // `beforeEach` will run before each test, re-deploying the contract every
  // time. It receives a callback, which can be async.
  beforeEach(async function() {
    // Get the ContractFactory and Signers here.
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // To deploy our contract, we just have to call Token.deploy() and await
    // for it to be deployed(), which happens onces its transaction has been
    // mined.

    httpProvider = new ethers.providers.JsonRpcProvider(
      "HTTP://127.0.0.1:7545"
    );
    dipToken = new ethers.Contract(
      dipTokenAbi.address[NETWORK],
      dipTokenAbi.abi,
      httpProvider
    );
    const FlightDelayStaking = await hre.ethers.getContractFactory(
      "FlightDelayStaking"
    );

    flightDelayStaking = await FlightDelayStaking.deploy(dipToken.address);

    await flightDelayStaking.deployed();

    await flightDelayStaking.setStakingRelation(10, 1);
    await flightDelayStaking.setExposureFactor(10);

    console.log(
      "FlightDelayStaking is deployed at",
      flightDelayStaking.address
    );
  });

  describe("Stake", function() {
    it("Should be able to stake", async function() {
      const requiredDips = await flightDelayStaking.calculateRequiredDip(
        ethers.utils.parseEther("1")
      );

      const ownerDipAmount = ethers.utils.formatEther(
        await dipToken.balanceOf(owner.address)
      );

      await dipToken
        .connect(owner)
        .approve(
          flightDelayStaking.address,
          ethers.utils.parseEther(ownerDipAmount)
        );
      await flightDelayStaking.stake(requiredDips, {
        value: ethers.utils.parseEther("1")
      });
      expect(
        await httpProvider.getBalance(flightDelayStaking.address)
      ).to.equal(ethers.utils.parseEther("1"));
      expect(await dipToken.balanceOf(owner.address)).to.equal(
        ethers.utils.parseEther(ownerDipAmount).sub(requiredDips)
      );
      expect(await dipToken.balanceOf(flightDelayStaking.address)).to.equal(
        requiredDips
      );
      expect((await flightDelayStaking.getStake(owner.address))[1]).to.equal(
        requiredDips
      );
    });

    it("Should be able to unstake", async function() {
      const requiredDips = await flightDelayStaking.calculateRequiredDip(
        ethers.utils.parseEther("1")
      );

      const ownerDipAmount = ethers.utils.formatEther(
        await dipToken.balanceOf(owner.address)
      );

      await dipToken
        .connect(owner)
        .approve(
          flightDelayStaking.address,
          ethers.utils.parseEther(ownerDipAmount)
        );
      await flightDelayStaking.stake(requiredDips, {
        value: ethers.utils.parseEther("1")
      });

      expect(
        await flightDelayStaking.getUnlockedStakeFor(owner.address)
      ).to.equal(ethers.utils.parseEther("1"));
      expect(
        await flightDelayStaking.calculateRequiredDip(
          ethers.utils.parseEther(".5")
        )
      ).to.equal(ethers.utils.parseEther("5"));

      await flightDelayStaking.unstake(ethers.utils.parseEther(".5"));

      expect(
        await httpProvider.getBalance(flightDelayStaking.address)
      ).to.equal(ethers.utils.parseEther(".5"));
      expect(
        await flightDelayStaking.getUnlockedStakeFor(owner.address)
      ).to.equal(ethers.utils.parseEther(".5"));
      expect(
        await flightDelayStaking.getUnlockedStakeFor(owner.address)
      ).to.equal(ethers.utils.parseEther(".5"));

      const [stableAmount, dipAmount] = await flightDelayStaking.getStake(
        owner.address
      );
      expect(stableAmount).to.equal(ethers.utils.parseEther(".5"));
      expect(dipAmount).to.equal(ethers.utils.parseEther("5"));
    });

    it("Should be able to purchase premium", async function() {
      const tx = await flightDelayStaking.receivePremium({
        value: ethers.utils.parseEther("10")
      });
      const receipt = await tx.wait();
      console.log("receivePremium: Receipt", receipt);
      expect(
        await httpProvider.getBalance(flightDelayStaking.address)
      ).to.equal(ethers.utils.parseEther("10"));
    });
  });
});
