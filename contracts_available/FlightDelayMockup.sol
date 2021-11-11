// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.6.11;

import "@etherisc/gif-interface/contracts/services/InstanceOperatorService.sol";
import "@etherisc/gif-interface/contracts/Product.sol";

contract FlightDelayMockup is Product {

    event LogAppliedForPolicy(
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay,
        uint256 _departureTime,
        uint256 _arrivalTime,
        uint256[] _payoutOptions
    );

    bytes32 public constant NAME = "FlightDelayEtheriscOracle";
    bytes32 public constant VERSION = "0.1.11";
    bytes32 public constant POLICY_FLOW = "PolicyFlowDefault";

    constructor(address _productController)
    public
    Product(_productController, NAME, POLICY_FLOW)
    {}

    function applyForPolicy(
    // domain specific
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay,
        uint256 _departureTime,
        uint256 _arrivalTime,
        uint256[] calldata _payoutOptions
    ) external payable {
        emit LogAppliedForPolicy(
            _carrierFlightNumber,
            _departureYearMonthDay,
            _departureTime,
            _arrivalTime,
            _payoutOptions
        );
    }

    function faucet() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}
