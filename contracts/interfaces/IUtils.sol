// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IUtils {
    function isTradable(uint256 id) external pure returns (bool);

    function isHero(uint256 id) external pure returns (bool);

    function isItem(uint256 id) external pure returns (bool);

    function itemId(uint256 id) external pure returns (uint96);

    function resourceType(uint256 id) external pure returns (uint16);

    function heroID(uint256 id) external pure returns (uint64);

    function heroRarity(uint256 id) external pure returns (uint8);

    function heroClass(uint256 id) external pure returns (uint8);

    function heroType(uint256 id) external pure returns (uint16);

    function getHeroTokenId(bool _isTradable, uint16 _type, uint8 _class, uint8 _rarity, uint64 _id) external pure returns (uint256);

    function getItemTokenId(bool _isTradable, uint96 _itemId) external pure returns (uint256);
}
