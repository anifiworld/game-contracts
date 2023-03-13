// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract USDToken is ERC20, ERC20Burnable {
    constructor() ERC20("USD Token", "USD") {
        _mint(msg.sender, 300000000 * 10 ** decimals());
    }
}
