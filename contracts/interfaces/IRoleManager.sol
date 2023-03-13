// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IRoleManager {
    function INITIALIZER_ROLE() external view returns (bytes32);
    function MINTER_ROLE() external view returns (bytes32);
    function ASSET_CONTROLLER_ROLE() external view returns (bytes32);
    function GAME_MANAGER_ROLE() external view returns (bytes32);
    function ORACLE_ROLE() external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}
