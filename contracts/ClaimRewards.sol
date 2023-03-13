// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
//import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract PrivateSale is Ownable {
    //using Chainlink for Chainlink.Request;
    uint256 public volume;
    bytes32 private jobId;
    uint256 private fee;

    event RequestVolume(bytes32 indexed requestId, uint256 volume);

    IERC20 public constant aniToken = IERC20(0x4c161d6Cf0ec884141c44c852510Ff5B1b2D5092);

    uint256 public initialTax = 3000;
    uint256 public periodTax = 15 * 24 * 60 * 60;
    address public treasury;
    bool public active;

    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public claimedAmount;

    modifier isActive {
        require(active == true, "Temporarily stop");
        _;
    }

    event OnClaimReward(address to, uint256 amount);

    constructor() public {
        //setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
        //setChainlinkOracle(0xf3FBB7f3391F62C8fe53f89B41dFC8159EE9653f);
        //jobId = 'ca98366cc7314957b8c012c72f05aeeb';
        //fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }
    //////////////////////

    function setActive (bool _active) external onlyOwner {
        active = _active;
    }

    function setFee (uint256 _fee) external onlyOwner {
        require (_fee > 0, "Cannot be zero");
        fee = _fee;
    }

    function setInitialTax (uint256 _tax) external onlyOwner {
        initialTax = _tax;
    }

    function setPeriodTax (uint256 _period) external onlyOwner {
        periodTax = _period;
    }

    function setTreasury (address _treasury) external onlyOwner {
        require(_treasury != address(0), "Address cannot be zero");
        treasury = _treasury;
    }

    function claim () external isActive {
        IERC20(aniToken).transfer(_msgSender(),10 * (10 ** 18));
        emit OnClaimReward(_msgSender(), 10 * (10 ** 18));
    }
}
