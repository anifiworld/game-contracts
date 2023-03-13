// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./interfaces/INFT.sol";
import "./interfaces/IHero.sol";
import "./interfaces/IUtils.sol";
import "./interfaces/ILP.sol";
import "./utils/CentralAccessControl.sol";
import "./vrf/VRFConsumerBaseV2.sol";
import "./vrf/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vendor is CentralAccessControl, VRFConsumerBaseV2 {

    ILP public lp;
    address public lpAddress;
    IERC20 public token;
    INFT public nft;
    IHero public hero;
    IUtils public utils;
    address public receiver;

    //Chainlink
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;
    uint256 public s_requestId;
    address s_owner;

    mapping(uint256 => uint256) public _priceMap;
    mapping(uint256 => uint256) public _rentalTimeMap;
    // Adddress => ItemId => TimeStamp
    mapping(address => mapping(uint256 => uint256)) public _expirationDate;
    mapping(uint256 => address) public _requestIdToAddressMap;
    mapping(uint256 => uint8) public _requestIdPendingBoxTypeMap;
    mapping(address => uint256[]) public lastClaim;

    struct Gacha {
        bool _requestingGacha;
        bool _finishedRandom;
        uint8 _boxAmount;
        uint256 _requestId;
    }

    mapping(address => Gacha) public gacha;
    mapping(address => uint256) private seed;

    event HeroPending(uint256 requestId, address to);
    event HeroTransferred(uint256 requestId, uint256[] tokenId, address to);
    event ItemTransferred(uint256 itemId, uint256 amount, uint256 expirationDate, address to);
    event ItemPriceSet(uint256 itemId, uint256 price, uint256 rentalTime);

    function initialize(address _roleManager, IUtils _utils, IERC20 _token, INFT _nft, IHero _hero, address _vrfCoordinator, bytes32 _keyHash, uint64 subscriptionId) public initializer {
        __CentralAccessControl_init(_roleManager);
        __VRFConsumerBase_init(_vrfCoordinator);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_owner = _msgSender();
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        token = _token;
        nft = _nft;
        hero = _hero;
        utils = _utils;
        callbackGasLimit = 100000;
        requestConfirmations = 3;
        numWords =  1;
        receiver = _msgSender();
    }

    function setLP(address _lp) public onlyRole(VENDOR_MANAGER_ROLE) {
        require(address(_lp) != address(0), "Invalid address");
        lp = ILP(_lp);
        lpAddress = _lp;
    }

    function setReceiver(address _receiver) public onlyRole(VENDOR_MANAGER_ROLE) {
        require(address(_receiver) != address(0), "Invalid address");
        receiver = _receiver;
    }

    function setItemPriceBatch(uint256[] memory _itemIds, uint256[] memory _prices, uint256[] memory _rentalTime) public onlyRole(VENDOR_MANAGER_ROLE) {
        require(_itemIds.length == _prices.length && _itemIds.length == _rentalTime.length, "Length mismatch");
        for (uint256 i = 0; i < _itemIds.length; i++) {
            setItemPrice(_itemIds[i], _prices[i], _rentalTime[i]);
        }
    }

    function setItemPrice(uint256 _itemId, uint256 _price, uint256 _rentalTime) public onlyRole(VENDOR_MANAGER_ROLE) {
        require(utils.isItem(_itemId) == true, "Invalid tokenId");
        if (_rentalTime > 0) {
            require(utils.itemId(_itemId) > 1000, "Reserved item can't rent");
            require(nft.totalSupply(_itemId) == 0 || _rentalTimeMap[_itemId] > 0, "Can't' change rentalTime");
            _rentalTimeMap[_itemId] = _rentalTime;
        }
        _priceMap[_itemId] = _price;
        emit ItemPriceSet(_itemId, _price, _rentalTime);
    }

    function buyItem(uint256 _itemId, uint256 _amount) external {
        require(_priceMap[_itemId] > 0, "Invalid item");
        require(_amount > 0, "Invalid amount");
        token.transferFrom(_msgSender(), receiver, getActualPrice(_priceMap[_itemId]) * _amount);
        uint256 rentalTime = _rentalTimeMap[_itemId];
        if (rentalTime > 0) {
            if (nft.balanceOf(_msgSender(), _itemId) == 0) {
                nft.mint(_msgSender(), _itemId, 1, "");
            }

            uint256 expirationDate = _expirationDate[_msgSender()][_itemId];
            if (expirationDate == 0 || expirationDate < block.timestamp) {
                expirationDate = block.timestamp;
            }
            uint256 nextExpire = expirationDate + (_amount * rentalTime);
            _expirationDate[_msgSender()][_itemId] = nextExpire;
            emit ItemTransferred(_itemId, _amount, nextExpire, _msgSender());
        } else {
            nft.mint(_msgSender(), _itemId, _amount, "");
            emit ItemTransferred(_itemId, _amount, 0, _msgSender());
        }
    }

    function openGachaHero(uint8 _boxType, uint8 _boxAmount) external {
        require(_boxType >= 1 && _boxType <= 4, "Invalid boxType");
        require(_boxAmount <= 10, "Must less than 10 boxes");
        require(gacha[_msgSender()]._requestingGacha == false, "Requesting Gacha");
        require(gacha[_msgSender()]._finishedRandom == false, "Not claim Gacha yet");
        uint256 gachaItemId = utils.getItemTokenId(true, _boxType);
        nft.burn(_msgSender(), gachaItemId, _boxAmount);
        uint256 requestId = getRandomNumber();
        _requestIdToAddressMap[requestId] = _msgSender();
        _requestIdPendingBoxTypeMap[requestId] = _boxType;
        gacha[_msgSender()]._requestId = requestId;
        gacha[_msgSender()]._requestingGacha = true;
        gacha[_msgSender()]._boxAmount = _boxAmount;
        emit HeroPending(requestId, _msgSender());
    }

    function getRandomNumber() private returns (uint256 requestId) {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        return s_requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        address owner = _requestIdToAddressMap[requestId];
        require(owner != address(0), "No requestedId");
        uint8 pendingBox = _requestIdPendingBoxTypeMap[requestId];
        require(pendingBox > 0, "Request fulfilled");
        seed[owner] = randomness[0];
        gacha[owner]._requestId = requestId;
        gacha[owner]._requestingGacha = false;
        gacha[owner]._finishedRandom = true;
    }

    function claimGacha() external returns (uint256[] memory) {
        require(gacha[_msgSender()]._finishedRandom != false, "Not finished yet");
        address owner = _requestIdToAddressMap[gacha[_msgSender()]._requestId];
        require(owner != address(0), "No requestedId");
        uint8 pendingBox = _requestIdPendingBoxTypeMap[gacha[_msgSender()]._requestId];
        require(pendingBox > 0, "Request fulfilled");
        uint256[] memory tokenId = new uint[](gacha[_msgSender()]._boxAmount);
        for (uint256 i = 0; i < gacha[_msgSender()]._boxAmount; i++) {
            tokenId[i] = hero.randomHero(owner, true, selfRandom(i, seed[_msgSender()]), pendingBox);
        }
        lastClaim[_msgSender()] = tokenId;
        _requestIdPendingBoxTypeMap[gacha[_msgSender()]._requestId] = 0;
        seed[_msgSender()] = 0;
        gacha[_msgSender()]._boxAmount = 0;
        gacha[_msgSender()]._finishedRandom = false;
        emit HeroTransferred(gacha[_msgSender()]._requestId, tokenId, owner);

        return tokenId;
    }

    function selfRandom(uint256 num, uint256 pRandom) internal pure returns (uint256) {
        return (uint256(keccak256(abi.encode(num, pRandom))));
    }

    function getExpirationDate(address _owner, uint256 _itemTokenId) external view returns (uint256 expirationDate) {
        return _expirationDate[_owner][_itemTokenId];
    }

    function getActualPrice(uint256 _price) public view returns (uint256){
        return (((IERC20(lp.token0()).balanceOf(lpAddress) * (10 ** 18)) / IERC20(lp.token1()).balanceOf(lpAddress)) * _price) / (10 ** 18);
    }
}
