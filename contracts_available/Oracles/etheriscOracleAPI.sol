pragma solidity 0.5.12;

interface EtheriscAddressResolverI {
    function getAddress() external returns (address _address);
}

contract usingEtheriscOracle {

    event LogOracleQuery(
        uint256 _timestamp,
        string _datasource,
        string _args,
        uint256 _reqId
    );

    uint256 public reqId = 0;
    address cbAddress;
    address[2] allEAR =[
        0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed, // xDai Mainnet
        0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1  // xDai Sokol Testnet
    ];

    EtheriscAddressResolverI EAR;

    function etheriscCbAddress() public returns (address _cbAddress) {
        if (cbAddress == address(0)) {
            etheriscSetNetwork();
        }
        return cbAddress;
    }

    function etheriscSetNetwork() internal returns (bool _networkSet) {

        for (uint8 idx = 0; idx < allEAR.length; idx = idx + 1) {
            if (getCodeSize(allEAR[idx]) > 0) {
                EAR = EtheriscAddressResolverI(allEAR[idx]);
                cbAddress = EAR.getAddress();
                return true;
            }
        }

        return false;
    }

    function __callback(
        bytes32 _myId,
        string memory _result
    )
        public
    {
        return;
        _myId;
        _result;
    }

    function _OracleQuery(
        uint256 _timestamp,
        string memory _arg1,
        string memory _arg2
    ) internal returns (bytes32 _id) {
        reqId = reqId + 1;
        emit LogOracleQuery(_timestamp, _arg1, _arg2, reqId);
        return keccak256(abi.encode(reqId));
    }

    function etheriscOracleQuery(
        uint256 _timestamp,
        string memory _arg1,
        string memory _arg2
    ) internal returns (bytes32 _id){
        return _OracleQuery(_timestamp, _arg1, _arg2);
    }

    function etheriscOracleQuery(
        uint256 _timestamp,
        string memory _arg1
    ) internal returns (bytes32 _id){
        return _OracleQuery(_timestamp, _arg1, "");
    }

    function etheriscOracleQuery(
        string memory _arg1,
        string memory _arg2
    ) internal returns (bytes32 _id){
        return _OracleQuery(0, _arg1, _arg2);
    }

    function etheriscOracleQuery(
        string memory _arg1
    ) internal returns (bytes32 _id){
        return _OracleQuery(0, _arg1, "");
    }

    function parseInt(string memory _a)
    internal
    pure
    returns (uint _parsedInt)
    {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b)
    internal
    pure
    returns (uint _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(
                uint8(bresult[i])
            ) <= 57)) {
                if (decimals) {
                    if (_b == 0) {
                        break;
                    } else {
                        _b--;
                    }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function strConcat(string memory _a, string memory _b)
    internal
    pure
    returns (string memory _concatenatedString)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c)
    internal
    pure
    returns (string memory _concatenatedString)
    {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function getCodeSize(address _addr) internal view returns (uint256 _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }



}
