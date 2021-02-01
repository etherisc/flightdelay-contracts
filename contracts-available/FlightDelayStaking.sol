// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FixedMath.sol";

interface IRewardDistributor {}

abstract contract DipToken is IERC20 {}

contract FlightDelayStaking is Ownable {
    using SafeMath for uint256;
    using FixedMath for uint256;

    /**
     * This struct keeps the double balance of DIP and stablecoin
     *
     */
    struct Stake {
        uint256 stable;
        uint256 dip;
    }

    /**
     * This event is triggered after a contributor has successfully staked a certain amount of DIP and stablecoin.
     *
     * @param _dipStake Amount of DIP staked, needs to be higher then calculateRequiredDip(_stableStake)
     * @param _stableStake Amount of stablecoin staked
     * @param _totalDipStake Total amount of DIP staked
     * @param _totalStableStake Total amount of stablecoin staked
     *
     */
    event LogDIPStaked(
        uint256 _dipStake,
        uint256 _stableStake,
        uint256 _totalDipStake,
        uint256 _totalStableStake
    );

    uint256 exposureFactor = 40;
    uint256 collatFactor = 50;
    uint256 bigNumber = 10**18;

    bool public isPublicStakable;
    uint256 public lastUnprocessedUnstakeRequest;

    Stake[] private unstakeRequests;
    mapping(address => Stake) public stakeBalances;

    uint256 public currentStake; // currentStake represents the current staking values.
    uint256 public targetStake; // targetStake represents staking values after unstake requests have been processed.
    // uint256 public totalLockedStake; // the currently locked Stake
    uint256 public policyCount;
    FixedUint public stakingRelation;

    IERC20 public dipTokenContract;

    /**
     * @param _dipContractAddress is DIP token address
     */
    constructor(address _dipContractAddress) public {
        dipTokenContract = DipToken(_dipContractAddress);
        setStakingRelation(1, 1);
    }

    /**
     * @dev Set staking ratio
     * @param _relation is the dip token amount
     * @param _divider is the stable amount
     */
    function setStakingRelation(uint256 _relation, uint256 _divider) public {
        stakingRelation.val = _relation;
        stakingRelation.div = _divider;
    }

    /**
     * @dev Stake stable and dip tokens
     * @param _stake is the amount of dip token
     *
     */
    function stake(uint256 _stake) public payable {
        Stake memory currentStakersStake = stakeBalances[msg.sender];
        uint256 totalStableStake = currentStakersStake.stable + msg.value;
        uint256 totalDipStake = currentStakersStake.dip + _stake;
        uint256 requiredDip = calculateRequiredDip(totalStableStake);
        require(totalDipStake <= requiredDip, "Stake to high");
        require(
            dipTokenContract.transferFrom(msg.sender, address(this), _stake),
            "DIP could not be staked"
        );
        stakeBalances[msg.sender] = Stake(totalStableStake, totalDipStake);
        currentStake += msg.value;

        emit LogDIPStaked(_stake, msg.value, totalDipStake, totalStableStake);
    }

    /**
     * @dev calculates required dip token amount from stable token amount. _requiredStake Amount of DIP tokens required.
     * @param _stableStake is the amount of stable coin
     */
    function calculateRequiredDip(uint256 _stableStake)
        public
        view
        returns (uint256 _requiredStake)
    {
        _requiredStake = _stableStake.fixedMul(stakingRelation);
    }

    /**
     * @dev calculates required stable amount from dip token amount.
     * @param _dipAmount is the amount of dip coin
     * @return _requiredStable is amount of stable
     */
    function calculateRequiredStable(uint256 _dipAmount)
        public
        view
        returns (uint256 _requiredStable)
    {
        _requiredStable = _dipAmount.fixedDiv(stakingRelation);
    }

    /**
     * @dev get the availabel amount of stable can be unstaked. returns _capacity Amount of DIP tokens required.
     */
    function getCapacity() public view returns (uint256 _capacity) {
        if (targetStake < totalLockedStake()) {
            return 0;
        }
        return targetStake - totalLockedStake();
    }

    /**
     * @dev locks the capacity
     * @param _capacity is the amount to lock
     *
     */
    function lockCapacity(uint256 _capacity) public {}

    /**
     * @dev unlocks the capacity
     * @param _capacity is the amount to unlock
     *
     */
    function unlockCapacity(uint256 _capacity) public {}

    /**
     * @dev add two stakes. _result is the added stakes
     * @param _s1 Stake
     * @param _s2 Stake
     */
    function addStake(Stake calldata _s1, Stake calldata _s2)
        public
        pure
        returns (Stake memory _result)
    {
        _result.dip = _s1.dip + _s2.dip;
        _result.stable = _s1.stable + _s2.stable;
    }

    /**
     * @dev get Stake of the address
     * @param staker is the address of the staker
     */
    function getStake(address staker)
        public
        view
        returns (Stake memory _stake)
    {
        return stakeBalances[staker];
    }

    /**
     * @dev get locked stake for staker
     * @param _staker staker address
     * @return _amount locked amount
     */

    function getLockedStakeFor(address _staker)
        public
        view
        returns (uint256 _amount)
    {
        if (currentStake == 0) return 0;

        uint256 stakedDai = stakeBalances[_staker].stable;

        uint256 locked =
            stakedDai
                .div(currentStake)
                .mul(totalLockedStake())
                .mul(collatFactor)
                .div(100);

        return locked;
    }

    /**
     * @dev get unlocked stake for staker
     * @param _staker staker address
     * @return _amount unlocked amount
     */

    function getUnlockedStakeFor(address _staker)
        public
        view
        returns (uint256 _amount)
    {
        Stake memory _stake = stakeBalances[_staker];

        return _stake.stable - getLockedStakeFor(_staker);
    }

    /**
     * @dev get maximum exposure
     * @return _capacity is maximum exposure
     */
    function maximumCapacity() public view returns (uint256 _capacity) {
        return currentStake.div(collatFactor).mul(100);
    }

    /**
     * @dev get total locked stakes
     * @return _amount is total locked stake
     */
    function totalLockedStake() public view returns (uint256 _amount) {
        return
            policyCount.mul(exposureFactor).mul(10).mul(bigNumber).mul(157).div(
                160
            );
    }

    /**
     * @dev get available exposure
     * @return _capacity is available exposure
     */
    function availableCapacity() public view returns (uint256 _capacity) {
        return
            maximumCapacity() -
            policyCount.mul(exposureFactor).mul(bigNumber).mul(150).div(800);
    }

    /**
     * @dev unstakes specific amount of staking
     * @param _amount is the dip amount to unstake
     *
     */
    function unstake(uint256 _amount) public payable {
        uint256 unlockedStable = getUnlockedStakeFor(_msgSender());
        uint256 unlockedDip = calculateRequiredDip(unlockedStable);
        uint256 requiredStable = calculateRequiredStable(_amount);

        require(_amount <= unlockedDip, "Unstake more than unlocked");
        require(requiredStable <= unlockedStable, "Unstake more than unlocked");

        dipTokenContract.transfer(_msgSender(), _amount);
        _msgSender().transfer(requiredStable);

        currentStake = currentStake.sub(requiredStable);
        Stake memory currentStakersStake = stakeBalances[msg.sender];
        uint256 totalStableStake =
            currentStakersStake.stable.sub(requiredStable);
        uint256 totalDipStake = currentStakersStake.dip.sub(_amount);

        stakeBalances[msg.sender] = Stake(totalStableStake, totalDipStake);
        // t.b.d
        // Unstaking strategy:
        // Assumption: The items in unstakeRequests are ordered in the sequence they have been recorded.
        // Pseudocode:
        //
        // Check if unstake request is valid, i.e. the contributor has actually staked that many tokens.
        // WHILE targetStake > lockedStake DO
        //   Iterate over unstakeRequests until an item is found which can be satisfied.
        //   IF none is found: RETURN
        //   Reduce currentStake and targetStake by this item.
        // DONE
        //
    }
}
