// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INFT is IERC1155Upgradeable {

    function MINT_ROLE() external returns (bytes32);

    function BURN_ROLE() external returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);
}
