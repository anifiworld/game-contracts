// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ILP {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address token) external view returns (uint256);
    function decimals() external pure returns (uint8);
}
