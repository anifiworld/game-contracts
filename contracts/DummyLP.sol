// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract DummyLP {
    address public token0;
    address public token1;
    constructor(address t1, address t2) {
        token0 = t1;
        token1 = t2;
    }

    function balanceOf(address token) public view returns (uint256){
        if (token == token0) {
            return 100 * (10 ** decimals());
        } else if (token == token1) {
            return 200 * (10 ** decimals());
        } else {
            return 0;
        }
    }

    function decimals() public pure returns (uint8){
        return 18;
    }
}
