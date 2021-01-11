pragma solidity 0.5.12;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IRewardDistributor {

}

contract FlightDelayRiskPool is Ownable {

    struct stake {
        uint256 stable;
        uint256 dip;
    }

    event LogDIPStaked(uint256 _stake, uint256 _amount, uint256 _totalDipStake, uint256 _totalStableStake);

    mapping (address => stake) public stakeBalances;

    IERC20 public DipTokenContract;

    constructor (address _DipContractAddress) {
        DipTokenContract = DipToken(_DipContractAddress);
    }

    function stake(uint256 _stake) public payable {

        stake currentStake = stakeBalances[msg.sender];
        uint256 totalStableStake = currentStake.stable + msg.value;
        uint256 totalDipStake = currentStake.dip + _stake;
        uint256 requiredDip = calculateRequiredDip(totalStableStake);
        require (totalDipStake <= requiredDip, "Stake to high");
        require (DipTokenContract.transferFrom(msg.sender, this, stake), "DIP could not be staked");
        stakeBalances[msg.sender] = stake(totalStableStake, totalDipStake);

        emit LogDIPStaked(stake, msg.value, totalDipStake, totalStableStake);

    }

    function getStake(address staker)
        public view
        returns (stake _stake)
    {
        return stakeBalances[staker];
    }

    function unstake(uint256 stake, uint256 stable)
        public
        returns (bool _success)
    {
        // t.b.d
        return true;
    }



}
