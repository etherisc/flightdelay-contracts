pragma solidity 0.5.12;

import "../GIF/Oracle.sol";
import "./etheriscOracleAPI.sol";
import "./strings.sol";

contract FlightStatusesOracle is Oracle, usingEtheriscOracle {
    using strings for *;

    modifier onlyOracle {
        require(msg.sender == etheriscCbAddress());
        _;
    }
    event OracleRequested(
        uint256 requestId,
        bytes32 queryId,
        uint256 time,
        string url
    );

    event OracleResponded(
        uint256 requestId,
        bytes32 queryId,
        string result
    );

    string constant STATUS_BASE_URL = "https://fs-api.etherisc.com/api/v1/status/";

    mapping(bytes32 => uint256) public requests;

    constructor(address _oracleController, string memory _encryptedQuery)
    public
    Oracle(_oracleController)
    {
    }

    function request(uint256 _requestId, bytes calldata _input) external onlyQuery {
        // todo: set permissions

        (uint256 oracleTime, bytes32 carrierFlightNumber, bytes32 departureYearMonthDay) = abi.decode(
            _input,
            (uint256, bytes32, bytes32)
        );

        string memory oracleUrl = getOracleUrl(
            carrierFlightNumber,
            departureYearMonthDay
        );

        bytes32 queryId = etheriscOracleQuery(
            oracleTime,
            oracleUrl
        );

        requests[queryId] = _requestId;

        emit OracleRequested(_requestId, queryId, oracleTime, oracleUrl);
    }

    function __callback(
        bytes32 _queryId,
        string memory _result
    )
        public
        onlyOracle
    {
        uint256 requestId = requests[_queryId];

        strings.slice memory slResult = _result.toSlice();

        // todo: add implementation
        slResult.find("\"".toSlice()).beyond("\"".toSlice());
        slResult.until(slResult.copy().find("\"".toSlice()));
        bytes1 status = bytes(slResult.toString())[0];
        // s = L

        if (status == "C") {
            // flight cancelled
            _respond(requestId, abi.encode(status, - 1));
        } else if (status == "D") {
            // flight diverted
            _respond(requestId, abi.encode(status, - 1));
        } else if (status != "L" && status != "A" && status != "C" && status != "D") {
            // Unprocessable status;
            _respond(requestId, abi.encode(status, - 1));
        } else {
            slResult = _result.toSlice();
            bool arrived = slResult.contains("actualGateArrival".toSlice());

            if (status == "A" || (status == "L" && !arrived)) {
                // flight still active or not at gate
                _respond(requestId, abi.encode(bytes1("A"), - 1));
            } else if (status == "L" && arrived) {
                strings.slice memory aG = "\"arrivalGateDelayMinutes\": ".toSlice();

                uint256 delayInMinutes;

                if (slResult.contains(aG)) {
                    slResult.find(aG).beyond(aG);
                    slResult.until(
                        slResult.copy().find("\"".toSlice()).beyond(
                            "\"".toSlice()
                        )
                    );
                    // truffle bug, replace by "}" as soon as it is fixed.
                    slResult.until(slResult.copy().find("\x7D".toSlice()));
                    slResult.until(slResult.copy().find(",".toSlice()));
                    delayInMinutes = parseInt(slResult.toString());
                } else {
                    delayInMinutes = 0;
                }

                _respond(requestId, abi.encode(status, delayInMinutes));
            } else {
                // no delay info
                _respond(requestId, abi.encode(status, - 1));
            }

        }

        emit OracleResponded(requestId, _queryId, _result);
    }

    function getOracleUrl(
        bytes32 _carrierFlightNumber,
        bytes32 _departureYearMonthDay
    )
        public
        pure
        returns (string memory _oracleUrl)
    {
        string memory url;

        url = strConcat(
            STATUS_BASE_URL,
            b32toString(_carrierFlightNumber),
            "/",
            b32toString(_departureYearMonthDay)
        );

        _oracleUrl = url;
    }

    function b32toString(bytes32 x) internal pure returns (string memory) {
        // gas usage: about 1K gas per char.
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;

        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);

        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }

        return string(bytesStringTrimmed);
    }
}
