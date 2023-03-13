// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract AniToken is ERC20, ERC20Burnable, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public wallet;
    address public constant BUSD = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    uint256 public fee;
    mapping (address => bool) public whitelist;

    event OnWhitelist(address _whitelist, bool _status);
    event OnSetFee(uint256 _fee);
    event OnSetWallet(address _wallet);

    constructor() ERC20("AToken", "AT") {
        _mint(msg.sender, 200000000 * 10 ** decimals());
        fee = 200;
        wallet = address(0x71B07e01DdE0adCbEbA8b635704043eC1f665E75);
        // BSC 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IUniswapV2Router02 _uniswapV2Router =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), BUSD);

        uniswapV2Router = _uniswapV2Router;

        whitelist[_msgSender()] = true;
        whitelist[address(this)] = true;
    }

    function addWhitelist (address _whitelist, bool _status) external onlyOwner {
        require (_whitelist != address(0), "Zero wallet");
        whitelist[_whitelist] = _status;
        emit OnWhitelist(_whitelist, _status);
    }

    function setFee (uint256 _fee) external onlyOwner {
        require (_fee <= 500, "Fee too high");
        fee = _fee;
        emit OnSetFee(_fee);
    }

    function setWallet (address _wallet) external onlyOwner {
        require (_wallet != address(0), "Zero wallet");
        wallet = _wallet;
        emit OnSetWallet(_wallet);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint256 feeAmount;
        if (!(whitelist[from] || whitelist[to])) {
            if (to == uniswapV2Pair) {
                feeAmount = amount * fee / 10000;
                amount -= feeAmount;
                super._transfer(from, address(this), feeAmount);
                _swap(feeAmount);
            }
        }
        super._transfer(from, to, amount);
    }

    function _swap(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;
        _approve(address(this), address(uniswapV2Router), _amount);
        uniswapV2Router.swapExactTokensForTokens(
            _amount,
            0,
            path,
            wallet,
            block.timestamp
        );
    }
}
