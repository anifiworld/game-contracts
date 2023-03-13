// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./AccessControlRoleList.sol";
import "../interfaces/IRoleManager.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CentralAccessControl is Initializable, AccessControlRoleList, ContextUpgradeable {

    IRoleManager roleManager;

    function __CentralAccessControl_init(address _roleManager) internal initializer {
        roleManager = IRoleManager(_roleManager);
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!roleManager.hasRole(role, account)) {
            revert(
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            )
            );
        }
    }
}
