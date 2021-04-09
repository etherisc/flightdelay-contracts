// const { expect } = require("chai");
const FlightDelayStaking = artifacts.require('FlightDelayStaking');
const MockDip = artifacts.require('MockDip');

contract('FlightDelayStaking', async (accounts) => {
  const [owner] = accounts;

  let flightDelayStaking;
  let mockDip;

  const halfEth = web3.utils.toWei('0.5', 'ether');
  const oneEth = web3.utils.toWei('1', 'ether');
  const fiveEth = web3.utils.toWei('5', 'ether');

  beforeEach(async () => {
    mockDip = await MockDip.new(
      'Mock Dip',
      'MDIP',
      web3.utils.toWei('100000', 'ether'),
    );

    console.log('MockDip is deployed at', mockDip.address);

    flightDelayStaking = await FlightDelayStaking.new(mockDip.address);

    await flightDelayStaking.setStakingRelation(10, 1);
    await flightDelayStaking.setExposureFactor(10);

    console.log(
      'FlightDelayStaking is deployed at',
      flightDelayStaking.address,
    );
  });

  it('should able to Stake', async () => {
    const requiredDips = await flightDelayStaking.calculateRequiredDip(oneEth);
    const ownerDipAmount = new web3.utils.BN(await mockDip.balanceOf(owner));

    await mockDip.approve(flightDelayStaking.address, ownerDipAmount, { from: owner });
    await flightDelayStaking.stake(requiredDips, { value: oneEth });

    expect(await web3.eth.getBalance(flightDelayStaking.address))
      .to.equal(oneEth, 'Contract eth balance is not correct after staking');
    expect((await mockDip.balanceOf(owner)).toString())
      .to.equal(ownerDipAmount.sub(requiredDips).toString(), 'Owner dip balance is not correct after staking');
    expect((await mockDip.balanceOf(flightDelayStaking.address)).toString())
      .to.equal(requiredDips.toString(), 'Contract dip balance is not correct after staking');
    expect((await flightDelayStaking.getStake(owner))[1].toString())
      .to.equal(requiredDips.toString(), 'Total stake of owner is not correct');
  });

  it('should able to unstake', async () => {
    const requiredDips = await flightDelayStaking.calculateRequiredDip(oneEth);
    const ownerDipAmount = new web3.utils.BN(await mockDip.balanceOf(owner));

    await mockDip.approve(flightDelayStaking.address, ownerDipAmount, { from: owner });
    await flightDelayStaking.stake(requiredDips, { value: oneEth });

    expect((await flightDelayStaking.getUnlockedStakeFor(owner)).toString())
      .to.equal(oneEth);
    expect((await flightDelayStaking.calculateRequiredDip(halfEth)).toString())
      .to.equal(fiveEth);

    await flightDelayStaking.unstake(halfEth);

    expect(await web3.eth.getBalance(flightDelayStaking.address))
      .to.equal(halfEth);
    expect((await flightDelayStaking.getUnlockedStakeFor(owner)).toString())
      .to.equal(halfEth);

    const stakeRes = await flightDelayStaking.getStake(owner);
    expect(stakeRes[0].toString())
      .to.equal(halfEth);
    expect(stakeRes[1].toString())
      .to.equal(fiveEth);
  });

  it('should able to purchase premium', async () => {
  });
});
