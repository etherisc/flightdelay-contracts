// SPDX-License-Identifier: Apache-2.0
pragma experimental ABIEncoderV2;
pragma solidity 0.6.11;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

interface IRewardDistributor {}

abstract contract DipToken is IERC20 {}

contract FlightDelayStaking is Ownable {
    using SafeMath for uint256;
    using FixedPoint for *;

    /**
     * This struct keeps the double balance of DIP and stablecoin
     *
     */
    struct Stake {
        uint256 stable;
        uint256 dip;
    }

    /**
     * @dev This struct is to keep premium purchases
     */
    struct Premium {
        uint256 expiresAt;
        address payerAddr;
        bool isClaimed;
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

    /**
     * @dev This event is triggered after a staker has successfully unstaked a certain amount of stablecoin and required dips
     * @param _stable amount of stables unstaked
     * @param _dip amount of dips unstaked
     * @param _curDipStake Current amount of DIP staked
     * @param _curStableStake Current amount of stablecoin staked
     */
    event LogUnstaked(
        uint256 _stable,
        uint256 _dip,
        uint256 _curStableStake,
        uint256 _curDipStake
    );

    uint256 exposureFactor = 40;
    uint256 collatFactor = 50;
    uint256 bigNumber = 10**18;

    bool public isPublicStakable;
    uint256 public lastUnprocessedUnstakeRequest;

    Stake[] private unstakeRequests;
    mapping(address => Stake) public stakeBalances;
    Premium[] private premiums;

    uint256 public currentStake; // currentStake represents the current staking values.
    uint256 public targetStake; // targetStake represents staking values after unstake requests have been processed.
    FixedPoint.uq112x112 public stakingRelation;

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
    function setStakingRelation(uint256 _relation, uint256 _divider)
        public
        onlyOwner
    {
        stakingRelation = FixedPoint.fraction(_relation, _divider);
    }

    /**
     * @dev Set staking ratio
     * @param _exposureFactor is the new exposureFactor
     */
    function setExposureFactor(uint256 _exposureFactor) public onlyOwner {
        exposureFactor = _exposureFactor;
    }

    /**
     * @dev Set staking ratio
     * @param _collatFactor is the new collatFactor
     */
    function setCollatFactor(uint256 _collatFactor) public onlyOwner {
        collatFactor = _collatFactor;
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
        require(totalDipStake == requiredDip, "Stake to not required amount");
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
        returns (uint144 _requiredStake)
    {
        _requiredStake = stakingRelation.mul(_stableStake).decode144();
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
        uint256 premiumCount = 0;

        for (uint256 i = 0; i < premiums.length; i += 1) {
            if (premiums[i].expiresAt <= block.timestamp) {
                premiumCount = premiumCount.add(1);
            }
        }

        return FixedPoint.fraction(98125, 100000).mul(premiumCount).decode144();
    }

    /**
     * @dev get available exposure
     * @return _capacity is available exposure
     */
    function availableCapacity() public view returns (uint256 _capacity) {
        return maximumCapacity() - totalLockedStake();
    }

    /**
     * @dev unstakes specific amount of staking
     * @param _stable is the stable amount to unstake
     *
     */
    function unstake(uint256 _stable) public payable {
        Stake memory _stake = stakeBalances[_msgSender()];

        require(
            _stake.stable >= _stable,
            "User staking balance is not enough!"
        );

        uint256 unlockedStable = getUnlockedStakeFor(_msgSender());
        uint256 requiredStable = _stable;

        if (requiredStable > unlockedStable) {
            uint256 remainingStable = _stable.sub(requiredStable);

            unstakeRequests.push(
                Stake(remainingStable, calculateRequiredDip(remainingStable))
            );
            requiredStable = unlockedStable;
        }

        uint256 requiredDip = calculateRequiredDip(requiredStable);

        dipTokenContract.transfer(_msgSender(), requiredDip);
        _msgSender().transfer(requiredStable);

        currentStake = currentStake.sub(requiredStable);
        Stake memory currentStakersStake = stakeBalances[msg.sender];
        uint256 totalStableStake =
            currentStakersStake.stable.sub(requiredStable);
        uint256 totalDipStake = currentStakersStake.dip.sub(requiredDip);

        stakeBalances[msg.sender] = Stake(totalStableStake, totalDipStake);

        emit LogUnstaked(
            requiredStable,
            requiredDip,
            totalStableStake,
            totalDipStake
        );
    }
}
