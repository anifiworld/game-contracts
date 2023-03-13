// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interfaces/IUtils.sol";
import "../utils/CentralAccessControl.sol";

contract NFT is ERC1155SupplyUpgradeable, CentralAccessControl, OwnableUpgradeable {
    string public name;
    string public symbol;
    string private _urinew;
    IUtils private utils;

    function initialize(address _roleManager, IUtils _utils) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __CentralAccessControl_init(_roleManager);
        name = "AniFi World Collection";
        symbol = "ANIFINFT";
        utils = _utils;
    }

    function setURI(string memory newuri) public onlyRole(INITIALIZER_ROLE) {
        _urinew = newuri;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(NFT_MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(NFT_MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value) public onlyRole(NFT_BURNER_ROLE) {
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public onlyRole(NFT_BURNER_ROLE) {
        _burnBatch(account, ids, values);
    }

    /** ERC1155 functions override */

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(utils.isTradable(id), "Untradable resources");
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        for (uint256 i = 0; i < ids.length; ++i) {
            require(utils.isTradable(ids[i]), "Untradable resources");
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string.concat(_urinew, StringsUpgradeable.toString(_tokenId));
    }
}
