// SPDX-License-Identifier: Apache-2.0
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
     * @notice This struct is to keep premium purchases
     */
    struct Premium {
        uint256 expiresAt;
        address payerAddr;
        bool isClaimed;
    }

    /**
     * @notice This struct is to keep unstake requests
     */
    struct UnstakeRequest {
        uint256 amount;
        uint256 fullFilled;
        bool paidOut;
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
     * @notice This event is triggered after a staker has successfully unstaked a certain amount of stablecoin and required dips
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
    uint256 policyFee = 10 * 10**18;

    bool public isPublicStakable;
    uint256 public lastUnprocessedUnstakeRequest;

    mapping(address => UnstakeRequest[]) private unstakeRequests;
    address[] private unstakeQueue;

    mapping(address => uint256) private currentStake;
    mapping(address => uint256) private targetStake;
    mapping(address => Stake) public stakeBalances;

    Premium[] private premiums;

    uint256 public totalCurrentStake; // currentStake represents the current staking values.
    uint256 public totalTargetStake; // targetStake represents staking values after unstake requests have been processed.
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
     * @notice Set staking ratio
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
     * @notice Set staking ratio
     * @param _exposureFactor is the new exposureFactor
     */
    function setExposureFactor(uint256 _exposureFactor) public onlyOwner {
        exposureFactor = _exposureFactor;
    }

    /**
     * @notice Set staking ratio
     * @param _collatFactor is the new collatFactor
     */
    function setCollatFactor(uint256 _collatFactor) public onlyOwner {
        collatFactor = _collatFactor;
    }

    /**
     * @notice calculates required dip token amount from stable token amount. _requiredStake Amount of DIP tokens required.
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
     * @notice locks the capacity
     * @param _capacity is the amount to lock
     *
     */
    function lockCapacity(uint256 _capacity) public {}

    /**
     * @notice unlocks the capacity
     * @param _capacity is the amount to unlock
     *
     */
    function unlockCapacity(uint256 _capacity) public {}

    /**
     * @notice get Stake of the address
     * @param staker is the address of the staker
     */
    function getStake(address staker) public view returns (uint256, uint256) {
        return (stakeBalances[staker].stable, stakeBalances[staker].dip);
    }

    /**
     * @notice get locked stake for staker
     * @param _staker staker address
     * @return _amount locked amount
     */

    function getLockedStakeFor(address _staker)
    public
    view
    returns (uint256 _amount)
    {
        if (totalCurrentStake == 0) return 0;

        uint256 stakedDai = stakeBalances[_staker].stable;

        uint256 locked =
        stakedDai
        .div(totalCurrentStake)
        .mul(totalLockedStake())
        .mul(collatFactor)
        .div(100);

        return locked;
    }

    /**
     * @notice get unlocked stake for staker
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
     * @notice get maximum exposure
     * @return _capacity is maximum exposure
     */
    function maximumCapacity() public view returns (uint256 _capacity) {
        return totalCurrentStake.div(collatFactor).mul(100);
    }

    /**
     * @notice get total locked stakes
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
     * @notice get available exposure
     * @return _capacity is available exposure
     */
    function availableCapacity() public view returns (uint256 _capacity) {
        return maximumCapacity() - totalLockedStake();
    }

    /**
     * @notice Stake stable and dip tokens
     * @param _stake is the amount of dip token
     *
     */
    function stake(uint256 _stake) public payable {
        Stake memory currentStakersStake = stakeBalances[_msgSender()];
        uint256 totalStableStake = currentStakersStake.stable + msg.value;
        uint256 totalDipStake = currentStakersStake.dip + _stake;
        uint256 requiredDip = calculateRequiredDip(totalStableStake);
        require(
            unstakeRequests[_msgSender()].length == 0,
            "Unstake request queue is not empty"
        );
        require(totalDipStake == requiredDip, "Stake to not required amount");
        require(
            dipTokenContract.transferFrom(_msgSender(), address(this), _stake),
            "DIP could not be staked"
        );
        stakeBalances[_msgSender()] = Stake(totalStableStake, totalDipStake);
        totalCurrentStake = totalTargetStake.add(msg.value);
        totalTargetStake = totalTargetStake.add(msg.value);
        currentStake[_msgSender()] = currentStake[_msgSender()].add(msg.value);
        targetStake[_msgSender()] = targetStake[_msgSender()].add(msg.value);

        emit LogDIPStaked(_stake, msg.value, totalDipStake, totalStableStake);
    }

    /**
     * @notice unstakes specific amount of staking
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

            unstakeRequests[_msgSender()].push(
                UnstakeRequest(remainingStable, 0, false)
            );
            unstakeQueue.push(_msgSender());

            targetStake[_msgSender()] = targetStake[_msgSender()].sub(
                remainingStable
            );
            requiredStable = unlockedStable;
        }

        uint256 requiredDip = calculateRequiredDip(requiredStable);

        dipTokenContract.transfer(_msgSender(), requiredDip);
        _msgSender().transfer(requiredStable);

        totalCurrentStake = totalCurrentStake.sub(requiredStable);
        totalTargetStake = totalTargetStake.sub(requiredStable);

        currentStake[_msgSender()] = currentStake[_msgSender()].sub(
            requiredStable
        );
        targetStake[_msgSender()] = targetStake[_msgSender()].sub(
            requiredStable
        );

        Stake memory currentStakersStake = stakeBalances[_msgSender()];

        uint256 totalStableStake =
        currentStakersStake.stable.sub(requiredStable);
        uint256 totalDipStake = currentStakersStake.dip.sub(requiredDip);

        stakeBalances[_msgSender()] = Stake(totalStableStake, totalDipStake);

        emit LogUnstaked(
            requiredStable,
            requiredDip,
            totalStableStake,
            totalDipStake
        );
    }

    /**
     * @notice removes a request of staker
     * @param _addr is the address of the request owner
     */
    function removeRequest(address _addr) internal {
        uint256 _index = unstakeQueue.length - 1;

        for (; _index >= 0; _index -= 1) {
            if (unstakeQueue[_index] == _addr) break;
        }

        for (uint256 i = _index; i < unstakeQueue.length - 1; i += 1) {
            unstakeQueue[i] = unstakeQueue[i + 1];
        }

        unstakeQueue.pop();
    }

    /**
     * @notice removes all requests of staker
     * @param _addr is the address of the request owner
     */
    function removeAllRequests(address _addr) internal {
        for (uint256 j = 0; j < unstakeRequests[_addr].length; j += 1) {
            uint256 _index = unstakeQueue.length - 1;

            for (; _index >= 0; _index -= 1) {
                if (unstakeQueue[_index] == _addr) break;
            }

            for (uint256 i = _index; i < unstakeQueue.length - 1; i += 1) {
                unstakeQueue[i] = unstakeQueue[i + 1];
            }

            unstakeQueue.pop();
        }
    }

    /**
     * @notice reverts the latest unstake request
     */
    function revertLastRequest() public {
        UnstakeRequest[] storage callerRequests = unstakeRequests[_msgSender()];
        require(callerRequests.length > 0, "No pending requests");

        uint256 lastIdx = callerRequests.length.sub(1);
        uint256 remainingRequest =
        callerRequests[lastIdx].amount.sub(
            callerRequests[lastIdx].fullFilled
        );

        totalTargetStake = totalTargetStake.add(remainingRequest);
        targetStake[_msgSender()] = targetStake[_msgSender()].add(
            remainingRequest
        );

        removeRequest(_msgSender());
        callerRequests.pop();
    }

    /**
     * @notice reverts the latest unstake request
     */
    function revertAllRequests() public {
        require(
            unstakeRequests[_msgSender()].length > 0,
            "No pending requests"
        );

        removeAllRequests(_msgSender());
        delete unstakeRequests[_msgSender()];

        uint256 remainingRequest =
        currentStake[_msgSender()].sub(targetStake[_msgSender()]);
        targetStake[_msgSender()] = currentStake[_msgSender()];
        totalTargetStake = totalTargetStake.add(remainingRequest);
    }

    /**
     * @notice receive premium fee (when policy is sold)
     */
    function receivePremium() public payable {
        require(msg.value == policyFee, "Not enough policy fee");
    }
}
