// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./interfaces/IUtils.sol";

contract Utils {
    function isTradable(uint256 id) external pure returns (bool) {
        return ((id >> 255 & 0x1) == 1);
    }

    function isHero(uint256 id) external pure returns (bool) {
        return (resourceType(id) == 1);
    }

    function isItem(uint256 id) external pure returns (bool) {
        return (resourceType(id) == 2);
    }

    function itemId(uint256 id) external pure returns (uint96) {
        return uint96(id & 0xFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function resourceType(uint256 id) public pure returns (uint16) {
        return uint16(id >> (64 + 8 + 8 + 16)) & 0xFFFF;
    }

    function heroID(uint256 id) external pure returns (uint64) {
        return uint64(id & 0xFFFFFFFFFFFFFFFF);
    }

    function heroRarity(uint256 id) external pure returns (uint8) {
        return uint8(id >> 64) & 0xFF;
    }

    function heroClass(uint256 id) external pure returns (uint8) {
        return uint8(id >> (64 + 8)) & 0xFF;
    }

    function heroType(uint256 id) external pure returns (uint16) {
        return uint16(id >> (64 + 8 + 8)) & 0xFFFF;
    }

    function getHeroTokenId(bool _isTradable, uint16 _type, uint8 _class, uint8 _rarity, uint64 _id) external pure returns (uint256){
        uint256 resultId = 0;
        if (_isTradable) {
            resultId += (1 << 255);
        }
        resultId += uint256(1) << 96;
        resultId += uint256(_type) << 80;
        resultId += uint256(_class) << 72;
        resultId += uint256(_rarity) << 64;
        resultId += _id;
        return resultId;
    }

    function getItemTokenId(bool _isTradable, uint96 _itemId) external pure returns (uint256){
        uint256 resultId = 0;
        if (_isTradable) {
            resultId += (1 << 255);
        }
        resultId += 2 << 96;
        resultId += _itemId;
        return resultId;
    }
}
