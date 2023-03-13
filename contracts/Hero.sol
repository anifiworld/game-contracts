// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./interfaces/INFT.sol";
import "./interfaces/IUtils.sol";
import "./interfaces/IHero.sol";
import "./utils/CentralAccessControl.sol";

contract Hero is CentralAccessControl {

    INFT public nft;
    IUtils public utils;
    uint64 latestHeroId;

    mapping(uint256 => IHero.Status) public _heroStats;

    event HeroStatusChanged(uint256 heroId, IHero.Status status);
    event HeroMinted(uint256 tokenId, IHero.Status status);
    event HeroDecomposed(address to, uint256 heroId, uint256 gotId, uint256 gotAmount);
    event HeroDecomposedBatch(address to, uint256[] heroId, uint256[] gotIds, uint256[] gotAmounts);
    event HeroUpgraded(address owner, uint256 heroId, uint32 toRank);

    function initialize(address _roleManager, INFT _nft, IUtils _utils) public initializer {
        __CentralAccessControl_init(_roleManager);
        nft = _nft;
        utils = _utils;
    }

    function randomHero(address _to, bool _isTradable, uint256 _randomness, uint8 _boxType) public onlyRole(HERO_MANAGER_ROLE) returns (uint256) {
        require(_boxType >= 1 && _boxType <= 4, "Invalid boxType");
        uint8[5] memory tempStat = [1, 1, 1, 1, 0];
        uint32 heroTypeSeed = uint32(_randomness & 0xFFFFFFFF);
        uint32 heroRaritySeed = uint32((_randomness >> 32) & 0xFFFFFFFF);
        uint40 heroStatSeed = uint40((_randomness >> 64) & 0xFFFFFFFFFF);
        uint8 maxStat;
        uint8 statPoint;
        uint8 _rarity;
        uint16 _type;
        if (_boxType == 4) {
            _type = 6;
        } else {
            if (heroTypeSeed < 858993459) {
                _type = 1;
            } else if (heroTypeSeed < 1717986918) {
                _type = 2;
            } else if (heroTypeSeed < 2576980377) {
                _type = 3;
            } else if (heroTypeSeed < 3435973836) {
                _type = 4;
            } else {
                _type = 5;
            }
        }

        // Common/Loki Box
        if (_boxType == 1 || _boxType == 4) {
            // 55.0000000046566% Common
            // 32.0000000065193% Uncommon
            // 10.0000000093132% Rare
            // 2.49999999068677% Epic
            // 0.499999988824129% Legend
            _rarity = getRandomRarity(heroRaritySeed, 2362232013, 3736621548, 4166118278, 4273492460);
        }
        // Uncommon Box
        else if (_boxType == 2) {
            // 10.0000000093132% Common
            // 55.0000000046566% Uncommon
            // 26.0000000009313% Rare
            // 7.49999999534339% Epic
            // 1.49999998975545% Legend
            _rarity = getRandomRarity(heroRaritySeed, 429496730, 2791728743, 3908420240, 4230542787);
        }
        // Rare Box
        else if (_boxType == 3) {
            // 0% Common
            // 10.0000000093132% Uncommon
            // 55.0000000046566% Rare
            // 27.4999999906868% Epic
            // 7.49999999534339% Legend
            _rarity = getRandomRarity(heroRaritySeed, 0, 429496730, 2791728743, 3972844749);
        } else {
            revert("Something wrong");
        }

        if (_rarity == 1) {
            statPoint = 16;
            maxStat = 8;
        } else if (_rarity == 2) {
            statPoint = 18;
            maxStat = 9;
        } else if (_rarity == 3) {
            statPoint = 20;
            maxStat = 10;
        } else if (_rarity == 4) {
            statPoint = 22;
            maxStat = 11;
        } else if (_rarity == 5) {
            statPoint = 24;
            maxStat = 12;
        }

        for (uint8 i = 0; i < statPoint; i++) {
            uint8 targetStatIndex = uint8(heroStatSeed & 0x3);
            _upStat(tempStat, targetStatIndex, maxStat);
            heroStatSeed = heroStatSeed >> 2;
        }
        IHero.Status memory stat = IHero.Status(tempStat[0], tempStat[1], tempStat[2], tempStat[3], tempStat[4]);
        return _mintHero(_to, _isTradable, _type, getClass(_type), _rarity, stat);
    }

    function getClass (uint16 _type) internal pure returns(uint8) {
        uint8 _class;
        if (_type == 1) {
            _class = 2;
        } else if (_type == 2) {
            _class = 1;
        } else if (_type == 3) {
            _class = 1;
        } else if (_type == 4) {
            _class = 2;
        } else if (_type == 5) {
            _class = 1;
        } else if (_type == 6) {
            _class = 2;
        } else {
            _class = 1;
        }
        return _class;
    }

    function getRandomRarity(uint32 _seed, uint32 _common, uint32 _uncommon, uint32 _rare, uint32 _epic) internal pure returns (uint8){
        if (_seed < _common) {
            return 1;
        }
        else if (_seed < _uncommon) {
            return 2;
        }
        else if (_seed < _rare) {
            return 3;
        }
        else if (_seed < _epic) {
            return 4;
        }
        return 5;
    }

    function _upStat(uint8[5] memory _currentStat, uint8 _statIndex, uint8 _max) internal {
        uint8 currentStatPoint = _currentStat[_statIndex];
        if (currentStatPoint >= _max)
            _upStat(_currentStat, (_statIndex + 1) % 4, _max);
        else
            _currentStat[_statIndex] = currentStatPoint + 1;
    }

    function _mintHero(address _to, bool _isTradable, uint16 _type, uint8 _class, uint8 _rarity, IHero.Status memory _status) internal returns (uint256) {
        require(_to != address(0), "Invalid address");
        uint64 heroId = ++latestHeroId;
        uint256 heroTokenId = utils.getHeroTokenId(_isTradable, _type, _class, _rarity, heroId);
        nft.mint(_to, heroTokenId, 1, "");
        _heroStats[heroTokenId] = _status;
        emit HeroMinted(heroTokenId, _status);
        return heroTokenId;
    }

    function mintHero(address _to, bool _isTradable, uint16 _type, uint8 _class, uint8 _rarity, IHero.Status memory _status) public onlyRole(HERO_MANAGER_ROLE) {
        _mintHero(_to, _isTradable, _type, _class, _rarity, _status);
    }

    function upgradeHero(uint256 _heroId) public {
        require(nft.balanceOf(_msgSender(), _heroId) == 1 && utils.isHero(_heroId), "Invalid heroId");
        uint32 curRank = _heroStats[_heroId].RANK;
        require(curRank < 5, "Maximum rank");
        uint256 fragmentAmount = (2 ** curRank) * utils.heroRarity(_heroId);
        nft.burn(_msgSender(), utils.getItemTokenId(true, 100 + utils.heroType(_heroId)), fragmentAmount);
        _heroStats[_heroId].RANK = curRank + 1;
        emit HeroUpgraded(_msgSender(), _heroId, curRank + 1);
    }

    function upgradeHeroTo(uint256 _heroId, uint32 _targetRank) public {
        require(nft.balanceOf(_msgSender(), _heroId) == 1 && utils.isHero(_heroId), "Invalid heroId");
        require(_targetRank <= 5, "Maximum rank exceeded");
        uint32 curRank = _heroStats[_heroId].RANK;
        require(curRank < _targetRank, "Invalid targetRank");
        uint32 rarity = utils.heroRarity(_heroId);
        uint256 fragmentAmount = 0;
        for (uint32 i = curRank; i <= _targetRank; i++) {
            fragmentAmount += (2 ** i) * rarity;
        }
        nft.burn(_msgSender(), utils.getItemTokenId(true, 100 + utils.heroType(_heroId)), fragmentAmount);
        _heroStats[_heroId].RANK = _targetRank;
        emit HeroUpgraded(_msgSender(), _heroId, _targetRank);
    }

    function decomposeHero(uint256 _heroId) external {
        require(nft.balanceOf(_msgSender(), _heroId) == 1 && utils.isHero(_heroId) && utils.isTradable(_heroId), "Invalid heroId");
        nft.burn(_msgSender(), _heroId, 1);
        uint256 mintId = utils.getItemTokenId(true, 100 + utils.heroType(_heroId));
        uint256 mintAmount = 2 ** (utils.heroRarity(_heroId) - 1);
        nft.mint(_msgSender(), mintId, mintAmount, "");
        emit HeroDecomposed(_msgSender(), _heroId, mintId, mintAmount);
    }

    function decomposeHeroBatch(uint256[] memory _heroIds) external {
        require(_heroIds.length > 0, "Empty Hero List");
        uint256[] memory amounts = new uint256[](_heroIds.length);
        uint256[] memory mintIds = new uint256[](_heroIds.length);
        uint256[] memory mintAmounts = new uint256[](_heroIds.length);
        for (uint256 i = 0; i < _heroIds.length; i++) {
            require(nft.balanceOf(_msgSender(), _heroIds[i]) == 1 && utils.isHero(_heroIds[i]) && utils.isTradable(_heroIds[i]), "Invalid heroId");
            amounts[i] = 1;
            mintIds[i] = utils.getItemTokenId(true, 100 + utils.heroType(_heroIds[i]));
            mintAmounts[i] = 2 ** (utils.heroRarity(_heroIds[i]) - 1);
        }
        nft.burnBatch(_msgSender(), _heroIds, amounts);
        nft.mintBatch(_msgSender(), mintIds, mintAmounts, "");
        emit HeroDecomposedBatch(_msgSender(), _heroIds, mintIds, mintAmounts);
    }
}
