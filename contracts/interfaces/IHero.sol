// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IHero {
    struct Status {
        uint32 STR;
        uint32 INT;
        uint32 VIT;
        uint32 AGI;
        uint32 RANK;
    }

    function randomHero(address _to, bool _isTradable, uint256 _randomness, uint8 _boxType) external returns (uint256);

    function mintFirstHero() external returns (uint256[] memory);

    function decomposeHero(uint256 _heroId) external;
}
