// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract MagiToken is ERC20, ERC20Burnable, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant pairCurrency = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    uint256 public lastMarkPrice;
    uint256 public lastMarkPriceTimestamp;
    uint256 public markPeriod;
    uint256 public limitChangePrice;
    uint256 public limitNewPrice;
    uint256 public inflationRate;
    bool public limitActive;
    mapping (address => bool) public whitelist;

    event OnWhitelist(address _whitelist, bool _status);
    event OnSetChangePrice(uint256 _limit);
    event OnSetNewPrice(uint256 _limit);
    event OnLimitActive(bool _status);
    event OnSetMarkPeriod(uint256 _period);

    constructor() ERC20("AToken", "AT") {
        _mint(msg.sender, 200000000 * 10 ** decimals());
        // BSC 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IUniswapV2Router02 _uniswapV2Router =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), pairCurrency);

        uniswapV2Router = _uniswapV2Router;

        whitelist[_msgSender()] = true;
        whitelist[address(this)] = true;
        limitChangePrice = 1.2 * 10 ** 18;
        limitNewPrice = 1.25 * 10 ** 18;
        limitActive = true;
        inflationRate = 500;
    }

    function setMarkPeriod (uint256 _period) external onlyOwner {
        require (_period > 0, "Period must be greater than 0");
        markPeriod = _period;
        emit OnSetMarkPeriod(_period);
    }

    function setChangePrice (uint256 _limit) external onlyOwner {
        require (_limit != uint256(0), "Invalid");
        limitChangePrice = _limit;
        emit OnSetChangePrice(_limit);
    }

    function setNewPrice (uint256 _limit) external onlyOwner {
        require (_limit != uint256(0), "Invalid");
        limitNewPrice = _limit;
        emit OnSetNewPrice(_limit);
    }

    function setLimitActive (bool _status) external onlyOwner {
        limitActive = _status;
        emit OnLimitActive(_status);
    }

    function setWhitelist (address _whitelist, bool _status) external onlyOwner {
        require (_whitelist != address(0), "Zero wallet");
        whitelist[_whitelist] = _status;
        emit OnWhitelist(_whitelist, _status);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == uniswapV2Pair && limitActive) {
            super._transfer(from, to, amount);
            if (!whitelist[to]) {
                uint256 balanceToken0 = IERC20(address(this)).balanceOf(address(this));
                uint256 balanceToken1 = IERC20(pairCurrency).balanceOf(address(this));
                uint256 _price = balanceToken1 * 10 ** 18 / balanceToken0;
                if ( block.timestamp >= (lastMarkPriceTimestamp + markPeriod)) {
                    if (lastMarkPrice * 10 ** 18 / _price >= limitNewPrice) {
                        lastMarkPrice = lastMarkPrice / limitNewPrice;
                        lastMarkPriceTimestamp = block.timestamp;
                    } else {
                        lastMarkPrice = _price;
                        lastMarkPriceTimestamp = block.timestamp;
                    }
                }
                require (lastMarkPrice * 10 ** 18 / _price >= limitChangePrice, "Price too low");
            }
        } else {
            super._transfer(from, to, amount);
        }
    }

    function mintInflation (uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }
}
