// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./utils/AccessControlRoleList.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoleManager is AccessControlUpgradeable, AccessControlRoleList {
    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(INITIALIZER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function grantRoles(bytes32[] memory roles, address[] memory addresses) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(roles.length == addresses.length, "Length mismatch");
        for (uint i = 0; i < roles.length; i++) {
            grantRole(roles[i], addresses[i]);
        }
    }
}
