// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrivateSale is Ownable {

    IERC20 public aniToken;
    IERC20 public usdToken;
    uint256 public totalSale;
    uint256 public privateSaleTimestamp;
    uint256 public tgeTimestamp;
    address public wallet;

    // USD bought
    mapping(address => uint256) public userBoughtAmount;
    // AniToken to receive
    mapping(address => uint256) public userWallet;
    // Withdrawn AniToken
    mapping(address => uint256) public userWithdrawn;
    mapping(address => uint256) public userLastWithdrawn;

    uint256 public constant MIN_BUY = 100 * (10 ** 18);
    uint256 public constant MAX_BUY = 1500 * (10 ** 18);
    uint256 public constant LIMIT_SALE = 20000000 * (10 ** 18);
    uint256 public constant STEPUP_PERIOD = 5 * 60;//1 * 60 * 60 * 24; // 3 days
    uint256 public constant TOTAL_STEP = 11; // 1 = single price
    uint256 public constant PRICE_PER_STEP = 1 * (10 ** 14); // 0.0001
    uint256 public constant VESTING_PERIOD = 60 * 60;//8 * 30 * 60 * 60 * 24; // 8 months
    uint256 public constant START_PRICE = 45 * (10 ** 14); // 0.0045

    event OnBuy(address from, uint256 usdAmount, uint256 aniAmount);
    event OnWithdraw(address to, uint256 amount, uint256 amountLeft);

    constructor(address _wallet, IERC20 _usdToken, uint256 _privateSaleTimestamp, uint256 _tgeTimestamp){
        require(_privateSaleTimestamp > block.timestamp, "Invalid Sale Time");
        require(_tgeTimestamp > block.timestamp, "Invalid TGETime");
        require(_tgeTimestamp > _privateSaleTimestamp, "TGE must be after private sale");
        require(_wallet != address(0), "Wallet cannot be 0");
        wallet = _wallet;
        usdToken = _usdToken;
        privateSaleTimestamp = _privateSaleTimestamp;
        tgeTimestamp = _tgeTimestamp;
    }

    function setAniToken(IERC20 _aniToken) external onlyOwner {
        require(address(_aniToken) != address(0), "Address cannot be 0");
        aniToken = _aniToken;
    }

    function setWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Address cannot be 0");
        wallet = _wallet;
    }

    function setPrivateSaleTimestamp(uint256 _privateSaleTimestamp) external onlyOwner {
        //require(_privateSaleTimestamp > block.timestamp, "Current time reach");
        //require(block.timestamp <= privateSaleTimestamp, "Can't change privateSaleTime anymore");
        //require(_privateSaleTimestamp + (STEPUP_PERIOD * TOTAL_STEP) < tgeTimestamp, "PrivateSale must end before TGE");
        privateSaleTimestamp = _privateSaleTimestamp;
    }

    function setTGETimestamp(uint256 _tgeTimestamp) external onlyOwner {
        //require(_tgeTimestamp > block.timestamp, "Current time reach");
        //require(block.timestamp <= tgeTimestamp, "Can't change TGETime anymore");
        //require(_tgeTimestamp > privateSaleTimestamp + (STEPUP_PERIOD * TOTAL_STEP), "TGE must after privateSale end");
        tgeTimestamp = _tgeTimestamp;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 currentPrice;
        uint256 stepPassed;
        if (block.timestamp < privateSaleTimestamp) {
            currentPrice = START_PRICE;
        } else {
            if ((block.timestamp - privateSaleTimestamp) / STEPUP_PERIOD >= TOTAL_STEP) {
                stepPassed = TOTAL_STEP - 1;
            } else {
                stepPassed = (block.timestamp - privateSaleTimestamp) / STEPUP_PERIOD;
            }
            currentPrice = START_PRICE + (stepPassed * PRICE_PER_STEP);
        }
        // Mock 0.0045
        return currentPrice;
    }

    function quoteTokenAmount(uint256 _usdAmount) public view returns (uint256) {
        uint256 quoteAmount = _usdAmount * (10 ** 18) / getCurrentPrice();
        return quoteAmount;
    }

    function addBuy(address _wallet, uint256 _usdAmount, uint256 _price) external onlyOwner {
        require(_price >= START_PRICE, "price too low");
        uint256 aniAmount = (_usdAmount * (10 ** 18) / _price);
        require(totalSale + aniAmount <= LIMIT_SALE, "Sale limit exceed");
        userWallet[_wallet] += aniAmount;
        userBoughtAmount[_wallet] += _usdAmount;
        totalSale += aniAmount;
        emit OnBuy(_wallet, _usdAmount, aniAmount);
    }

    // USD 18 Decimals
    function buy(uint256 _usdAmount) external {
        require(isEligibleToBuy(), "Not eligible to buy");
        uint256 currentUSDAmount = userBoughtAmount[_msgSender()];
        require(currentUSDAmount + _usdAmount >= MIN_BUY, "Buy amount too low");
        require(currentUSDAmount + _usdAmount <= MAX_BUY, "Buy amount exceed limit");
        //uint256 aniAmount = (_usdAmount * (10 ** 18) / getCurrentPrice());
        uint256 aniAmount = quoteTokenAmount(_usdAmount);
        require(totalSale + aniAmount <= LIMIT_SALE, "Sale limit exceed");
        usdToken.transferFrom(_msgSender(), wallet, _usdAmount);
        userWallet[_msgSender()] += aniAmount;
        userBoughtAmount[_msgSender()] += _usdAmount;
        totalSale += aniAmount;
        emit OnBuy(_msgSender(), _usdAmount, aniAmount);
    }

    function withdraw() external {
        require(block.timestamp >= tgeTimestamp, "Not TGE yet");
        uint256 withdrawAmount = getWithdrawAmount();
        require(withdrawAmount > 0, "Nothing to withdraw");
        uint256 withdrawnBefore = userWithdrawn[_msgSender()];
        uint256 withdrawnAfter = withdrawnBefore + withdrawAmount;
        uint256 totalBalance = userWallet[_msgSender()];
        require(withdrawnAfter <= totalBalance, "Exceeded balance");
        userWithdrawn[_msgSender()] = withdrawnAfter;
        aniToken.transfer(_msgSender(), withdrawAmount);
        emit OnWithdraw(_msgSender(), withdrawAmount, totalBalance - withdrawnAfter);
    }

    function getWithdrawAmount() public view returns (uint256) {
        uint256 releasingTGE = 20 * userWallet[_msgSender()] / 100;
        uint256 afterTGE = userWallet[_msgSender()] - releasingTGE;
        uint256 lastWithdraw;
        if (userLastWithdrawn[_msgSender()] == 0) {
            lastWithdraw = tgeTimestamp;
        } else {
            lastWithdraw = userLastWithdrawn[_msgSender()];
        }
        uint256 withdrawVesting = (block.timestamp - lastWithdraw) * afterTGE / VESTING_PERIOD;
        uint256 withdrawAmount;
        if (userWithdrawn[_msgSender()] == 0) {
            withdrawAmount = releasingTGE + withdrawVesting;
        } else {
            withdrawAmount = withdrawVesting;
        }
        return withdrawAmount;
    }

    function isEligibleToBuy() public view returns (bool){
        uint256 buyUntil = privateSaleTimestamp + (STEPUP_PERIOD * TOTAL_STEP);
        return block.timestamp < tgeTimestamp && block.timestamp < buyUntil && block.timestamp >= privateSaleTimestamp;
    }
}
