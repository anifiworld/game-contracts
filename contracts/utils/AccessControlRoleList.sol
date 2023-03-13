// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract AccessControlRoleList {
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");
    bytes32 public constant NFT_MINTER_ROLE = keccak256("NFT_MINTER_ROLE");
    bytes32 public constant NFT_BURNER_ROLE = keccak256("NFT_BURNER_ROLE");
    bytes32 public constant ASSET_CONTROLLER_ROLE = keccak256("ASSET_CONTROLLER_ROLE");
    bytes32 public constant GAME_MANAGER_ROLE = keccak256("GAME_MANAGER_ROLE");
    bytes32 public constant VENDOR_MANAGER_ROLE = keccak256("VENDOR_MANAGER_ROLE");
    bytes32 public constant HERO_MANAGER_ROLE = keccak256("HERO_MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
}
