pragma solidity 0.5.12;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/math/safeMath.sol";
import "./FixedMath.sol";

interface IRewardDistributor {

}

contract FlightDelayRiskPool is Ownable {

    using SafeMath for uint256;
    using FixedMath for uint256;

    /**
     * This struct keeps the double balance of DIP and stablecoin
     *
     */
    struct stake {
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
    event LogDIPStaked(uint256 _dipStake, uint256 _stableStake, uint256 _totalDipStake, uint256 _totalStableStake);

    /**
     * This mapping keeps the record of stakers balance.
     *
     * @param address Address of staker
     * @returns stake A stake record representing the staked amount of DIP and stablecoin
     *
     */
    mapping (address => stake) public stakeBalances;

    /**
     * If an unstake request of a contributor cannot be satisfied immediately, it is queued.
     * The array stake[] keeps the queue of unprocessed requests.
     * lastUnprocessedUnstakeRequest points to the last unprocessed element.
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    stake[] unstakeRequests;
    uint256 lastUnprocessedUnstakeRequest;

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    bool public isPublicStakable;

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    stake public currentStake; // currentStake represents the current staking values.
    stake public targetStake; // targetStake represents staking values after unstake requests have been processed.
    stake public lockedStake; // the currently locked stake
    fixedUint public stakingRelation;

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    IERC20 public DipTokenContract;

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    constructor (address _DipContractAddress) {
        DipTokenContract = DipToken(_DipContractAddress);
        setStakingRelation(1,1);
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function setStakingRelation (uint256 _relation, uint256 _divider) public {
        stakingRelation.val = _relation;
        stakingRelation.div = _divider;
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function stake(uint256 _stake) public payable {

        stake currentStakersStake = stakeBalances[msg.sender];
        increaseCurrentStake(_stake);
        uint256 totalStableStake = currentSingleStake.stable + msg.value;
        uint256 totalDipStake = currentStake.dip + _stake;
        uint256 requiredDip = calculateRequiredDip(totalStableStake);
        require (totalDipStake <= requiredDip, "Stake to high");
        require (DipTokenContract.transferFrom(msg.sender, this, stake), "DIP could not be staked");
        stakeBalances[msg.sender] = stake(totalStableStake, totalDipStake);

        emit LogDIPStaked(stake, msg.value, totalDipStake, totalStableStake);

    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function calculateRequiredDip(uint256 _stableStake) public view returns (uint256 _requiredStake) {
        _requiredStake = fixedMul(_stableStake, stakingRelation);
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function getCapacity() public view returns (uint256 _capacity) {
        if (targetStake.stable < lockedStake.stable) {
            return 0;
        }
        return targetStake.stable - lockedStake.stable;
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function lockCapacity(uint256 _capacity) public {
        // add _capacity to lockedStake
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function unlockCapacity(uint256 _capacity) public {
        // subtract _capacity from lockedStake
        // process unstakeRequests
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function addStake(stake _s1, stake _s2) public pure returns (_stake _result) {
        _result.dip = _s1.dip + _s2.dip;
        _result.stable = _s1.stable + _s2.stable;
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function addStake(stake _s1, stake _s2) public pure returns (_stake _result) {
        _result.dip = _s1.dip + _s2.dip;
        _result.stable = _s1.stable + _s2.stable;
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function getStake(address staker)
        public view
        returns (stake _stake)
    {
        return stakeBalances[staker];
    }

    /**
     * Calculate the required DIP tokens to stake the requested amount of stable asset
     * Currently we use a fixed factor e.g. 1.0
     *
     * @param _stableStake
     * @returns _requiredStake Amount of DIP tokens required.
     *
     */
    function unstake(uint256 _stake, uint256 _stable)
        public
        returns (bool _success)
    {
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
        return true;
    }



}
