// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './IFairdrop.sol';

// https://github.com/Uniswap/merkle-distributor
contract Fairdrop is IFairdrop, Ownable {
    using ECDSA for bytes32;

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
        signer = signer_;
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
        string memory nonce_,
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
        bytes32 hash = keccak256(abi.encode(account_, userId_, nonce_, expiredAt_, address(this)))
            .toEthSignedMessageHash();
        if (!_verify(hash, v_, r_, s_)) {
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

        return true;
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
     * @dev verify if a signature is signed by signer
     */
    function _verify(
        bytes32 hash_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal view returns (bool isSignedBySigner) {
        isSignedBySigner = hash_.recover(v_, r_, s_) == signer;
    }
}
