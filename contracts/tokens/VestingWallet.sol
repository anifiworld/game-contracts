// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract VestingWallet is Context {
    event ERC20Locked(uint256 vestingId, address beneficiary, uint256 amount, uint64 releaseTimestamp);
    event ERC20Released(uint256 vestingId, address beneficiary, uint256 amount);

    struct VestingSchedule {
        address beneficiary;
        uint64 releaseTimestamp;
        uint256 amount;
        bool released;
    }

    uint256 public totalReleased;

    //Id of vesting slot, increase value by 1 when call vesting
    uint256 private _currentVestingId;

    //Map vestingId to VestingSchedule data
    mapping(uint256 => VestingSchedule) private _vestingSchedule;

    //GCR Token contract address
    IERC20 immutable token;

    // Limit 4 years (365 * 4 days = 126144000 seconds)
    uint256 private constant MAX_LIMIT = 126144000;

    constructor(
        address _tokenContract
    ) {
        require(_tokenContract != address(0), "VestingWallet: _tokenContract is zero address");
        token = IERC20(_tokenContract);
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary(uint256 _vestingId) external view returns (address) {
        return _vestingSchedule[_vestingId].beneficiary;
    }

    /**
     * @dev Getter for the release timestamp.
     */
    function releaseTimestamp(uint256 _vestingId) external view returns (uint256) {
        return _vestingSchedule[_vestingId].releaseTimestamp;
    }

    /**
     * @dev Amount left
     */
    function amount(uint256 _vestingId) external view returns (uint256) {
        return _vestingSchedule[_vestingId].amount;
    }

    /**
     * @dev Released amount
     */
    function released(uint256 _vestingId) external view returns (bool) {
        return _vestingSchedule[_vestingId].released;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release(uint256 _vestingId) external {
        uint64 _releaseTimestamp = _vestingSchedule[_vestingId].releaseTimestamp;
        uint256 _releaseAmount = _vestingSchedule[_vestingId].amount;
        address _beneficiary = _vestingSchedule[_vestingId].beneficiary;
        require(block.timestamp > _releaseTimestamp, "Cannot release yet");
        require(!_vestingSchedule[_vestingId].released, "Already release");
        require(_beneficiary == _msgSender(), "Sender must be beneficiary");
        _vestingSchedule[_vestingId].released = true;
        totalReleased += _releaseAmount;
        emit ERC20Released(_vestingId, _beneficiary, _releaseAmount);
        SafeERC20.safeTransfer(token, _beneficiary, _releaseAmount);
    }

    /**
     * @dev Lock the tokens to beneficiary address
     *
     * Emits a {ERC20Locked} event.
     */
    function vesting(uint256 _amount, uint64 _releaseTimestamp, address _beneficiary, bytes memory signature) external {
        require(verify(_beneficiary, _amount, _releaseTimestamp, signature), "Invalid signature");
        require(_amount > 0, "Invalid amount");
        require(_releaseTimestamp > block.timestamp, "Timestamp must greater than current time");
        require(_releaseTimestamp <= block.timestamp + MAX_LIMIT, "Timestamp must lesser than max limit");
        _vestingSchedule[++_currentVestingId] = VestingSchedule(_beneficiary, _releaseTimestamp, _amount, false);
        emit ERC20Locked(_currentVestingId, _beneficiary, _amount, _releaseTimestamp);
        SafeERC20.safeTransferFrom(token, _msgSender(), address(this), _amount);
    }

    function getMessageHash(
        address _beneficiary,
        uint _amount,
        uint64 _releaseTimestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_beneficiary, _amount, _releaseTimestamp));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function verify(
        address _beneficiary,
        uint _amount,
        uint64 _releaseTimestamp,
        bytes memory signature
    ) public pure returns (bool) {
        require(_beneficiary != address(0), "Beneficiary address is zero");
        bytes32 messageHash = getMessageHash(_beneficiary, _amount, _releaseTimestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _beneficiary;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        require(v == 27 || v == 28, "Invalid v");
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
