// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.6.11;

import "openzeppelin-solidity/contracts/utils/Pausable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract IRiskPool is Pausable, Ownable {

    receive() external virtual payable;
    function authorize(address _addr) external virtual;
    function requestPayment(address payable _receiver, uint256 _amount) external virtual;

}
