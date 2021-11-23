// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "@etherisc/gif-interface/contracts/0.7/Product.sol";

contract FlightDelayChainlink is Product {

    bytes32 public constant NAME = "FlightDelayChainlink";
    bytes32 public constant VERSION = "0.1.4";

    event LogRequestFlightRatings(uint256 requestId, bytes32 carrierFlightNumber, uint256 departureTime, uint256 arrivalTime, bytes32 riskId);
    event LogRequestFlightStatus(uint256 requestId, uint256 arrivalTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay);
    event LogRequestPayout(bytes32 bpKey, uint256 claimId, uint256 payoutId, uint256 amount);
    event LogError(string error, uint256 index, uint256 stored, uint256 calculated);
    event LogUnprocessableStatus(bytes32 bpKey, uint256 requestId);
    event LogPolicyExpired(bytes32 bpKey);
    event LogRequestPayment(bytes32 bpKey, uint256 requestId);
    event LogUnexpectedStatus(bytes32 bpKey, uint256 requestId, bytes1 status, int256 delay);

    event LogCallback(bytes32 _bytes, bytes _data);


    bytes32 public constant POLICY_FLOW = "PolicyFlowDefault";

    // Minimum observations for valid prediction
    uint256 public constant MIN_OBSERVATIONS = 10;
    // Minimum time before departure for applying
    uint256 public constant MIN_TIME_BEFORE_DEPARTURE = 24 hours;
    // Maximum duration of flight
    uint256 public constant MAX_FLIGHT_DURATION = 2 days;
    // Check for delay after .. minutes after scheduled arrival
    uint256 public constant CHECK_OFFSET = 3 hours;

    // uint256 public constant MIN_PREMIUM = 15 * 10 ** 18; // production
    // All amounts in cent = multiplier is 10 ** 16!
    uint256 public constant MIN_PREMIUM = 0 * 10 ** 16; // for testing purposes
    uint256 public constant MAX_PREMIUM = 15 * 10 ** 16;
    uint256 public constant MAX_PAYOUT = 750  * 10 ** 16;
    uint256 public constant MARGIN_PERCENT = 30;
    string public constant RATINGS_CALLBACK = "flightRatingsCallback";
    string public constant STATUSES_CALLBACK = "flightStatusCallback";

    // ['observations','late15','late30','late45','cancelled','diverted']
    uint8[6] public weightPattern = [0, 0, 0, 30, 50, 50];

    // Maximum cumulated weighted premium per risk
    uint256 public constant MAX_TOTAL_PAYOUT = 3 * MAX_PAYOUT; // we accept max 3 passengers per flight

    struct Risk {
        bytes32 carrierFlightNumber;
        bytes32 departureYearMonthDay;
        uint256 departureTime;
        uint256 arrivalTime;
        uint delayInMinutes;
        uint8 delay;
        uint256 estimatedMaxTotalPayout;
        uint256 premiumMultiplier;
        uint256 weight;
    }

    mapping(bytes32 => Risk) public risks;

    uint256 public uniqueIndex;
    bytes32 public ratingsOracleType;
    uint256 public ratingsOracleId;
    bytes32 public statusesOracleType;
    uint256 public statusesOracleId;

    constructor(
        address _productServiceAddress,
        bytes32 _ratingsOracleType,
        uint256 _ratingsOracleId,
        bytes32 _statusesOracleType,
        uint256 _statusesOracleId
    )
        public
        Product(_productServiceAddress, NAME, POLICY_FLOW)
    {
        setOracles(_ratingsOracleType, _ratingsOracleId, _statusesOracleType, _statusesOracleId);
    }

    function setOracles(
        bytes32 _ratingsOracleType,
        uint256 _ratingsOracleId,
        bytes32 _statusesOracleType,
        uint256 _statusesOracleId
    )
        public
        onlyOwner
    {
        ratingsOracleType = _ratingsOracleType;
        ratingsOracleId = _ratingsOracleId;
        statusesOracleType = _statusesOracleType;
        statusesOracleId = _statusesOracleId;
    }

    function uniqueId(address _addr)
        internal
        returns (bytes32 _uniqueId)
    {
        uniqueIndex += 1;
        return keccak256(abi.encode(_addr, productId, uniqueIndex));
    }

    function getValue() internal returns(uint256) {
        return msg.value;
    }

    function applyForPolicy(
        // domain specific
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay,
        uint256 _departureTime,
        uint256 _arrivalTime,
        uint256[5] memory _payouts
    ) external payable {
        // Validate input parameters

        uint256 premium = getValue();
        bytes32 bpKey = uniqueId(msg.sender);

        require(premium >= MIN_PREMIUM, "ERROR:FDD-001:INVALID_PREMIUM");
        require(premium <= MAX_PREMIUM, "ERROR:FDD-002:INVALID_PREMIUM");
        require(_arrivalTime > _departureTime, "ERROR:FDD-003:ARRIVAL_BEFORE_DEPARTURE_TIME");
        /* for demo uncommented ********************************************************/
        require(
            _arrivalTime <= _departureTime + MAX_FLIGHT_DURATION,
            "ERROR:FDD-004:INVALID_ARRIVAL/DEPARTURE_TIME"
        );
        require(
            _departureTime >= block.timestamp + MIN_TIME_BEFORE_DEPARTURE,
            "ERROR:FDD-005:INVALID_ARRIVAL/DEPARTURE_TIME"
        );
        /* end uncommented section *****************************************************/
        // Create risk if not exists
        bytes32 riskId = keccak256(abi.encode(_carrierFlightNumber, _departureTime, _arrivalTime));
        Risk storage risk = risks[riskId];

        if (risk.carrierFlightNumber == "") {
            risk.carrierFlightNumber = _carrierFlightNumber;
            risk.departureYearMonthDay = _departureYearMonthDay;
            risk.departureTime = _departureTime;
            risk.arrivalTime = _arrivalTime;
        }

        require (
            premium * risk.premiumMultiplier + risk.estimatedMaxTotalPayout < MAX_TOTAL_PAYOUT,
            "ERROR:FDD-006:CLUSTER_RISK"
        );

        // if this is the first policy for this flight,
        // we "block" this risk by setting risk.estimatedMaxTotalPayout to
        // the maximum. Next flight for this risk can only be insured after this one has been underwritten.
        if (risk.estimatedMaxTotalPayout == 0) {
            risk.estimatedMaxTotalPayout = MAX_TOTAL_PAYOUT;
        }

        // Create new application
        _newApplication(bpKey, abi.encode(premium, _payouts, msg.sender, riskId));

        // Request flight ratings
        uint256 requestId = _request(
            bpKey,
            abi.encode(_carrierFlightNumber),
            RATINGS_CALLBACK,
            ratingsOracleType,
            ratingsOracleId
        );

        emit LogRequestFlightRatings(
            requestId,
            _carrierFlightNumber,
            _departureTime,
            _arrivalTime,
            riskId
        );
    }

    function flightRatingsCallback(
        uint256 _requestId,
        bytes32 _bpKey,
        bytes calldata _response
    ) external onlyOracle {

        // Statistics: ['observations','late15','late30','late45','cancelled','diverted']
        uint256[6] memory _statistics = abi.decode(_response, (uint256[6]));
        (uint256 premium, uint256[5] memory payouts, /* address payable sender */, bytes32 riskId) =
        abi.decode(_getApplicationData(_bpKey), (uint256,uint256[5],address,bytes32));
        if (_statistics[0] < MIN_OBSERVATIONS) {
            _decline(_bpKey);
            // TODO: payback !
            return;
        }

        (uint256 weight, uint256[5] memory calculatedPayouts) = calculatePayouts(premium, _statistics);
        Risk storage risk = risks[riskId];

        for (uint256 i = 0; i < 5; i++) {
            if (calculatedPayouts[i] > MAX_PAYOUT) {
                emit LogError("ERROR:FDD-007:PAYOUT_GT_MAXPAYOUT", i, payouts[i], calculatedPayouts[i]);
                _decline(_bpKey);
                return;
            }
            if (calculatedPayouts[i] != payouts[i]) {
                emit LogError("ERROR:FDD-008:INVALID_PAYOUT_OPTION", i, payouts[i], calculatedPayouts[i]);
                _decline(_bpKey);
                return;
            }
        }

        // It's the first policy for this risk, we accept any premium
        if (risk.premiumMultiplier == 0) {
            risk.premiumMultiplier = 100000 / weight;
            risk.estimatedMaxTotalPayout = 0;
        }
        uint256 estimatedMaxPayout = premium * risk.premiumMultiplier;
        if (estimatedMaxPayout > MAX_PAYOUT) { estimatedMaxPayout = MAX_PAYOUT; }
        risk.estimatedMaxTotalPayout = risk.estimatedMaxTotalPayout + estimatedMaxPayout;
        risk.weight = weight;

        _underwrite(_bpKey);

        uint256 requestId = _request(
            _bpKey,
            abi.encode(
                risk.arrivalTime + CHECK_OFFSET,
                risk.carrierFlightNumber,
                risk.departureYearMonthDay
            ),
            STATUSES_CALLBACK,
            statusesOracleType,
            statusesOracleId
        );

        // Now everything is prepared
        // address(RiskPool).transfer(premium);

        emit LogRequestFlightStatus(
            requestId,
            risk.arrivalTime + CHECK_OFFSET,
            risk.carrierFlightNumber,
            risk.departureYearMonthDay
        );

    }

    function flightStatusCallback(uint256 _requestId, bytes32 _bpKey, bytes calldata _response)
        external
        onlyOracle
    {
        (bytes1 status, int256 delay) = abi.decode(_response, (bytes1, int256));
        (/* uint256 premium */, uint256[5] memory payouts, /* address payable sender */, /* bytes32 riskId */) =
        abi.decode(_getApplicationData(_bpKey), (uint256,uint256[5],address,bytes32));

        if (status != "L" && status != "A" && status != "C" && status != "D") {
            emit LogUnprocessableStatus(_bpKey, _requestId);
            return;
        }

        if (status == "A") {
            // todo: active, reschedule oracle call + 45 min
            emit LogUnexpectedStatus(_bpKey, _requestId, status, delay);
            return;
        }

        if (status == "C") {
            resolvePayout(_bpKey, payouts[3]);
        } else if (status == "D") {
            resolvePayout(_bpKey, payouts[4]);
        } else if (delay >= 15 && delay < 30) {
            resolvePayout(_bpKey, payouts[0]);
        } else if (delay >= 30 && delay < 45) {
            resolvePayout(_bpKey, payouts[1]);
        } else if (delay >= 45) {
            resolvePayout(_bpKey, payouts[2]);
        } else {
            resolvePayout(_bpKey, 0);
        }
    }

    function resolvePayout(bytes32 _bpKey, uint256 _payoutAmount) internal {
        if (_payoutAmount == 0) {
            _expire(_bpKey);
            emit LogPolicyExpired(_bpKey);
        } else {
            uint256 claimId = _newClaim(_bpKey, abi.encode(_payoutAmount));
            uint256 payoutId = _confirmClaim(_bpKey, claimId, abi.encode(_payoutAmount));
            _payout(_bpKey, payoutId, true, abi.encode(_payoutAmount));

            emit LogRequestPayout(_bpKey, claimId, payoutId, _payoutAmount);
            // TODO: perform actual payout.
            // actual payment is performed in the wrapper contract
            // address payable customerAddress = customers[_policyId];
            // RiskPool.requestPayment(customerAddress, _payoutAmount);
        }
    }

    function calculatePayouts(uint256 _premium, uint256[6] memory _statistics)
        public
        view
        returns (uint256 _weight, uint256[5] memory _payoutOptions)
    {
        require(_premium >= MIN_PREMIUM, "ERROR:FDD-009:INVALID_PREMIUM");
        require(_premium <= MAX_PREMIUM, "ERROR:FDD-010:INVALID_PREMIUM");
        require(_statistics[0] >= MIN_OBSERVATIONS, "ERROR:FDD-011:LOW_OBSERVATIONS");

        _weight = 0;
        _payoutOptions = [uint256(0), 0, 0, 0, 0];

        for (uint256 i = 1; i < 6; i++) {
            _weight += weightPattern[i] * _statistics[i] * 10000 / _statistics[0];
            // 1% = 100 / 100% = 10,000
        }

        // To avoid div0 in the payout section, we have to make a minimal assumption on weight
        if (_weight == 0) {
            _weight = 100000 / _statistics[0];
        }

        _weight = _weight * (100 + MARGIN_PERCENT) / 100;

        for (uint256 i = 0; i < 5; i++) {
            _payoutOptions[i] = _premium * weightPattern[i + 1] * 10000 / _weight;

            if (_payoutOptions[i] > MAX_PAYOUT) {
                _payoutOptions[i] = MAX_PAYOUT;
            }
        }
    }

    function faucet() // for testing only
        public
        onlyOwner
    {
        address payable receiver;
        receiver = payable(owner());
        receiver.transfer(address(this).balance);
    }
}
