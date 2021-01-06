pragma solidity 0.5.12;

import "./etheriscOracleAPI.sol";
import "./strings.sol";
import "../GIF/Oracle.sol";

contract FlightRatingsOracle is Oracle, usingEtheriscOracle {
    using strings for *;

    modifier onlyOracle {
        require(msg.sender == etheriscCbAddress());
        _;
    }

    event OracleRequested(uint256 requestId, bytes32 queryId, string url);

    event OracleResponded(
        uint256 requestId,
        bytes32 queryId,
        string result
    );

    string constant RATINGS_BASE_URL = "https://fs-api.etherisc.com/api/v1/ratings";

    mapping(bytes32 => uint256) public requests;

    constructor(address _oracleController, string memory _encryptedQuery)
        public
        Oracle(_oracleController)
    {
    }

    function request(uint256 _requestId, bytes calldata _input)
        external
        onlyQuery
    {
        // todo: set permissions
        bytes32 carrierFlightNumber = abi.decode(_input, (bytes32));

        string memory oracleUrl = getOracleUrl(carrierFlightNumber);

        bytes32 queryId = etheriscOracleQuery(oracleUrl);

        requests[queryId] = _requestId;

        emit OracleRequested(_requestId, queryId, oracleUrl);
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

        if (bytes(_result).length == 0) {
            revert("Declined (empty result)");
        } else {
            if (slResult.count(", ".toSlice()) != 5) {
                revert("Declined (invalid result)");
            } else {
                slResult.beyond("[".toSlice()).until("]".toSlice());

                uint[6] memory statistics;

                for (uint i = 0; i <= 5; i++) {
                    statistics[i] = parseInt(
                        slResult.split(", ".toSlice()).toString()
                    );
                }

                _respond(requestId, abi.encode(statistics));
            }
        }

        emit OracleResponded(requestId, _queryId, _result);
    }

    function getOracleUrl(bytes32 _carrierFlightNumber)
        public
        pure
        returns (string memory _oracleUrl)
    {
        string memory url;

        url = strConcat(
            RATINGS_BASE_URL,
            b32toString(_carrierFlightNumber)
        );

        _oracleUrl = url;
    }

    function b32toString(bytes32 x)
        internal
        pure
        returns (string memory)
    {
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
