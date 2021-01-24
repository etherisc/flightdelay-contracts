// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

    struct fixedUint {
        uint256 val;
        uint256 div;
    }

library FixedMath {

    using SafeMath for uint256;

    function fixedMul(uint256 _f1, fixedUint memory _f2) public pure returns (uint256 _product) {
        return (_f1.mul(_f2.val)).div(_f2.div);
    }

}

