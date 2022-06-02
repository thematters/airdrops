// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/access/Ownable.sol';
import 'openzeppelin-contracts/utils/cryptography/ECDSA.sol';
import 'openzeppelin-contracts/token/ERC20/IERC20.sol';

import './IFairdrop.sol';

// https://github.com/Uniswap/merkle-distributor
contract Fairdrop is IFairdrop, Ownable {
    address public immutable token;
    address public signer;
    uint256 public amountPerAddress;

    mapping(address => bool) public addressClaimed;
    mapping(bytes32 => bool) public userIdClaimed;

    constructor(
        address token_,
        address signer_,
        address owner_,
        uint256 amountPerAddress_
    ) {
        token = token_;
        signer_ = signer_;
        amountPerAddress = amountPerAddress_;

        // immediately transfer ownership to a multisig
        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    //////////////////////////////
    /// Claim
    //////////////////////////////

    /// @inheritdoc IFairdrop
    function claim(
        address account_,
        bytes32 userId_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool success) {
        // Check if the claim is expired
        if (expiredAt_ < block.timestamp) {
            revert ClaimExpired();
        }

        // Check if the address/userId has already claimed a fairdrop
        if (addressClaimed[account_]) {
            revert AddressAlreadyClaimed(account_);
        }
        if (userIdClaimed[userId_]) {
            revert UserIdAlreadyClaimed(userId_);
        }

        // Verify the signature
        if (!_verify(_hash(account_, userId_, expiredAt_), v_, r_, s_)) {
            revert InvalidSignature();
        }

        // Mark as claimed
        addressClaimed[account_] = true;
        userIdClaimed[userId_] = true;

        // Transfer tokens
        uint256 amount = amountPerAddress;
        if (!IERC20(token).transfer(account_, amount)) {
            revert TransferFailed(account_, amount);
        }

        emit Claimed(account_, userId_, amount);
    }

    /// @inheritdoc IFairdrop
    function setAmountPerAddress(uint256 amount_) external onlyOwner {
        amountPerAddress = amount_;
        emit AmountChanged(amount_);
    }

    //////////////////////////////
    /// Withdraw
    //////////////////////////////

    /// @inheritdoc IFairdrop
    function sweep(address target_) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));

        tokenContract.transfer(target_, balance);
        emit Swept(target_, balance);
    }

    /// @inheritdoc IFairdrop
    function sweepToOwner() external {
        address target = owner();
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));

        tokenContract.transfer(target, balance);
        emit Swept(target, balance);
    }

    //////////////////////////////
    /// Verify
    //////////////////////////////

    /// @inheritdoc IFairdrop
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
        emit SignerChanged(signer_);
    }

    /**
     * @dev hash of the signed message
     */
    function _hash(
        address account_,
        bytes32 userId_,
        uint256 expiredAt_
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(account_, userId_, expiredAt_, address(this)));
    }

    /**
     * @dev verify if a signature is signed by signer
     */
    function _verify(
        bytes32 hash_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal view returns (bool) {
        return (ECDSA.recover(ECDSA.toEthSignedMessageHash(hash_), v_, r_, s_) == signer);
    }
}
