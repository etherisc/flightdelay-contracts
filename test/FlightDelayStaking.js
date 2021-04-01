// const { expect } = require("chai");
const FlightDelayStaking = artifacts.require("FlightDelayStaking");
const MockDip = artifacts.require("MockDip");

contract("FlightDelayStaking", async accounts => {
  const [owner] = accounts;

  let flightDelayStaking;
  let mockDip;

  beforeEach(async function() {
    mockDip = await MockDip.new(
      "Mock Dip",
      "MDIP",
      web3.utils.toWei("100000", "ether")
    );

    console.log("MockDip is deployed at", mockDip.address);

    flightDelayStaking = await FlightDelayStaking.new(mockDip.address);

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

    const ownerDipAmount = new web3.utils.BN(await mockDip.balanceOf(owner));

    await mockDip.approve(flightDelayStaking.address, ownerDipAmount, {
      from: owner
    });

    await flightDelayStaking.stake(requiredDips, {
      value: web3.utils.toWei("1", "ether")
    });

    expect(await web3.eth.getBalance(flightDelayStaking.address)).to.equal(
      web3.utils.toWei("1", "ether"),
      "Contract eth balance is not correct after staking"
    );

    console.log(ownerDipAmount.toString());

    expect((await mockDip.balanceOf(owner)).toString()).to.equal(
      ownerDipAmount.sub(requiredDips).toString(),
      "Owner dip balance is not correct after staking"
    );

    expect(
      (await mockDip.balanceOf(flightDelayStaking.address)).toString()
    ).to.equal(
      requiredDips.toString(),
      "Contract dip balance is not correct after staking"
    );

    expect((await flightDelayStaking.getStake(owner))[1].toString()).to.equal(
      requiredDips.toString(),
      "Total stake of owner is not correct"
    );
  });

  it("should able to unstake", async () => {
    const requiredDips = await flightDelayStaking.calculateRequiredDip(
      web3.utils.toWei("1", "ether")
    );

    const ownerDipAmount = new web3.utils.BN(await mockDip.balanceOf(owner));

    await mockDip.approve(flightDelayStaking.address, ownerDipAmount, {
      from: owner
    });

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
