//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.11;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";

contract MockDip is ERC20Burnable {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 initialSupply
    ) public ERC20(_tokenName, _tokenSymbol) {
        _mint(_msgSender(), initialSupply);
    }
}
