// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.6.11;

import "openzeppelin-solidity/contracts/utils/Pausable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract IRiskPool is Pausable, Ownable {

    function receivePremium() external virtual payable;
    function lock(uint256 _amount) external virtual;
    function unlock(uint256 _amount) external virtual;
    function authorize(address _addr) external virtual;
    function requestPayment(address payable _receiver, uint256 _amount) external virtual;

}
