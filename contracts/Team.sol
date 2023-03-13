// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./interfaces/INFT.sol";
import "./interfaces/IUtils.sol";
import "./utils/CentralAccessControl.sol";

contract Team is CentralAccessControl {

    INFT public nft;
    IUtils public utils;

    mapping(address => uint256[5]) _teamMap;

    event HeroTeamSet(address sender);

    function initialize(address _roleManager, INFT _nft, IUtils _utils) public initializer {
        __CentralAccessControl_init(_roleManager);
        nft = _nft;
        utils = _utils;
    }

    function setTeam(uint256[5] memory _heroes) external {
        for (uint256 i = 0; i < _heroes.length; i++) {
            uint256 tokenId = _heroes[i];
            if (tokenId != 0) {
                setHeroAtIndex(i, tokenId);
            } else {
                removeHeroAtIndex(i);
            }
        }
        emit HeroTeamSet(_msgSender());
    }

    function removeHeroAtIndex(uint256 _index) private {
        _teamMap[_msgSender()][_index] = 0;
    }

    function setHeroAtIndex(uint256 _index, uint256 _tokenId) private {
        require(utils.isHero(_tokenId), "Not hero");
        require(nft.balanceOf(_msgSender(), _tokenId) == 1, "Not owned hero");
        uint256[5] memory teamArray = _teamMap[_msgSender()];
        for (uint256 i = 0; i < teamArray.length; i++) {
            if (i != _index && teamArray[i] == _tokenId) {
                revert("Can't use same hero id");
            }
        }
        _teamMap[_msgSender()][_index] = _tokenId;
    }

    function validateTeam(address _team) external view returns (bool) {
        uint256[5] memory teamArray = _teamMap[_team];
        for (uint256 i = 0; i < teamArray.length; i++) {
            if (teamArray[i] != 0 && nft.balanceOf(_team, teamArray[i]) == 0) {
                return false;
            }
        }
        return true;
    }
}
