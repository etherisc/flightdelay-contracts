// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.6.11;

import "openzeppelin-solidity/contracts/utils/Pausable.sol";
import "./IRiskPool.sol";

contract RiskPool is IRiskPool {

    modifier onlyAuthorized {
        require(authorizedSenders[msg.sender]);
        _;
    }

    event LogIncomingPayment(address _sender, uint256 _value);


    mapping (address => bool) public authorizedSenders;

    receive() external override payable {
        emit LogIncomingPayment(msg.sender, msg.value);
    }

    function authorize(address _addr) external override onlyOwner {
        authorizedSenders[_addr] = true;
    }


    function requestPayment(address payable _receiver, uint256 _amount) external override onlyAuthorized whenNotPaused {
        _receiver.transfer(_amount);
    }

}
