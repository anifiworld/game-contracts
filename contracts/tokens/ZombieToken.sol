// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
    unchecked {
        _balances[account] += amount;
    }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
    }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract ZombieToken is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant pairCurrency = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address public wallet;
    uint256 public fee;
    uint256 public lastMarkPrice;
    uint256 public lastMarkPriceTimestamp;
    uint256 public markPeriod;
    uint256 public limitChangePrice;
    uint256 public limitNewPrice;
    bool public limitActive;
    mapping (address => bool) public whitelist;

    event OnWhitelist(address _whitelist, bool _status);
    event OnSetChangePrice(uint256 _limit);
    event OnSetNewPrice(uint256 _limit);
    event OnLimitActive(bool _status);
    event OnSetMarkPeriod(uint256 _period);
    event OnSetFee(uint256 _fee);

    constructor() ERC20("ZToken", "ZT") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
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
        fee = 200;
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
        } else if (to == uniswapV2Pair && fee >= 0) {
            if (!(whitelist[from] || whitelist[to])) {
                feeAmount = amount * fee / 10000;
                amount -= feeAmount;
                _swap(feeAmount);
            }
            super._transfer(from, to, amount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _swap(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pairCurrency;
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
