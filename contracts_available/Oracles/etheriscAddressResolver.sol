pragma solidity 0.5.12;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract etheriscAddressResolver is Ownable {

    address public addr;

    function getAddress() public view returns (address _addr) {
        return addr;
    }

    function setAddress(address _addr) public onlyOwner {
        addr = _addr;
    }
}
