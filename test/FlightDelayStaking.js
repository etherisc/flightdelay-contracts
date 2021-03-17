// const { expect } = require("chai");
const FlightDelayStaking = artifacts.require("FlightDelayStaking");
const mockDipJson = require("../abis/MockDip.json");

contract("FlightDelayStaking", async accounts => {
  const [owner] = accounts;
  const DIPTokenLocal = "0xD2f3b9ac26F296f9e843769ea0204FdF9E32347c";

  let flightDelayStaking;
  let dipToken;

  beforeEach(async function() {
    dipToken = new web3.eth.Contract(mockDipJson.abi, DIPTokenLocal);
    flightDelayStaking = await FlightDelayStaking.new(DIPTokenLocal);

    await flightDelayStaking.setStakingRelation(10, 1);
    await flightDelayStaking.setExposureFactor(10);

    console.log(
      "FlightDelayStaking is deployed at",
      flightDelayStaking.address
    );
  });

  it("should able to Stake", async () => {
    const requiredDips = await flightDelayStaking.calculateRequiredDip(
      web3.utils.toWei("1", "ether")
    );

    const ownerDipAmount = new web3.utils.BN(
      await dipToken.methods.balanceOf(owner).call()
    );

    await dipToken.methods
      .approve(flightDelayStaking.address, ownerDipAmount)
      .send({ from: owner });

    await flightDelayStaking.stake(requiredDips, {
      value: web3.utils.toWei("1", "ether")
    });

    expect(await web3.eth.getBalance(flightDelayStaking.address)).to.equal(
      web3.utils.toWei("1", "ether")
    );

    expect(await dipToken.methods.balanceOf(owner).call()).to.equal(
      ownerDipAmount.sub(requiredDips).toString()
    );

    expect(
      await dipToken.methods.balanceOf(flightDelayStaking.address).call()
    ).to.equal(requiredDips.toString());

    expect((await flightDelayStaking.getStake(owner))[1].toString()).to.equal(
      requiredDips.toString()
    );
  });

  it("should able to unstake", async () => {
    const requiredDips = await flightDelayStaking.calculateRequiredDip(
      web3.utils.toWei("1", "ether")
    );

    const ownerDipAmount = new web3.utils.BN(
      await dipToken.methods.balanceOf(owner).call()
    );

    await dipToken.methods
      .approve(flightDelayStaking.address, ownerDipAmount)
      .send({ from: owner });

    await flightDelayStaking.stake(requiredDips, {
      value: web3.utils.toWei("1", "ether")
    });

    expect(
      (await flightDelayStaking.getUnlockedStakeFor(owner)).toString()
    ).to.equal(web3.utils.toWei("1", "ether"));
    expect(
      (
        await flightDelayStaking.calculateRequiredDip(
          web3.utils.toWei("0.5", "ether")
        )
      ).toString()
    ).to.equal(web3.utils.toWei("5", "ether"));

    await flightDelayStaking.unstake(web3.utils.toWei("0.5", "ether"));

    expect(await web3.eth.getBalance(flightDelayStaking.address)).to.equal(
      web3.utils.toWei("0.5", "ether")
    );
    expect(
      (await flightDelayStaking.getUnlockedStakeFor(owner)).toString()
    ).to.equal(web3.utils.toWei("0.5", "ether"));
    expect(
      (await flightDelayStaking.getUnlockedStakeFor(owner)).toString()
    ).to.equal(web3.utils.toWei("0.5", "ether"));

    const stakeRes = await flightDelayStaking.getStake(owner);
    expect(stakeRes[0].toString()).to.equal(web3.utils.toWei("0.5", "ether"));
    expect(stakeRes[1].toString()).to.equal(web3.utils.toWei("5", "ether"));
  });

  it("should able to purchase premium", async () => {});
});
