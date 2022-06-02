// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title Interface for fairdrop contract
 *
 * The fairdrop
 *
 * @author Michael Bauer <michael@m-bauer.org>
 */
interface IFairdrop {
    //////////////////////////////
    /// Error types
    //////////////////////////////

    /**
     * @dev Address has already claimed the fairdrop.
     */
    error AddressAlreadyClaimed(address account);

    /**
     * @dev Address has already claimed the fairdrop.
     */
    error UserIdAlreadyClaimed(bytes32 userId);

    /**
     * @dev The fairdrop claiming has expired.
     */
    error ClaimExpired();

    /**
     * @dev Invalid signature.
     */
    error InvalidSignature();

    /**
     * @dev Failed to transfer tokens.
     */
    error TransferFailed(address account, uint256 amount);

    //////////////////////////////
    /// Event types
    //////////////////////////////

    /**
     * @notice Drop is claimed.
     * @param account Address that claimed the drop.
     * @param userId Hashed User ID that claimed the drop.
     * @param amount Amount of tokens that were claimed.
     */
    event Claimed(address indexed account, bytes32 indexed userId, uint256 amount);

    /**
     * @notice Unclaimed funds were swept.
     * @param target Address that received the funds.
     * @param amount Amount of tokens that were swept.
     */
    event Swept(address indexed target, uint256 amount);

    /**
     * @notice Amount is changed.
     * @param amount New amount.
     */
    event AmountChanged(uint256 amount);

    /**
     * @notice Signer is changed.
     * @param signer New signer of the fairdrop.
     */
    event SignerChanged(address indexed signer);

    //////////////////////////////
    /// Claim
    //////////////////////////////

    /**
     * @notice Claim a fairdrop.
     *
     * @dev Throws: `AlreadyClaimed` or `ClaimExpired` error.
     * @dev Emits: `Claimed` events.
     *
     * @param account_ Address that claims the drop.
     * @param userId_ Hashed User ID that claims the drop.
     * @param expiredAt_ Timestamp when the drop expires.
     * @param v_ Signature field.
     * @param r_ Signature field.
     * @param s_ Signature field.
     * @return success Whether the claim was successful.
     */
    function claim(
        address account_,
        bytes32 userId_,
        uint256 expiredAt_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool success);

    /**
     * @notice Set the amount of tokens can be claimed per address.
     * @param amount_ New amount.
     */
    function setAmountPerAddress(uint256 amount_) external;

    //////////////////////////////
    /// Withdraw
    //////////////////////////////

    /**
     * @notice Sweep any unclaimed funds
     * @dev Transfers the full tokenbalance from the contract to `target` address.
     *
     * @param target_ Address that should receive the unclaimed funds
     */
    function sweep(address target_) external;

    /**
     * @notice Sweep any unclaimed funds to owner address
     * @dev Transfers the full tokenbalance from the contract to owner of contract.
     */
    function sweepToOwner() external;

    //////////////////////////////
    /// Verify
    //////////////////////////////

    /**
     * @notice Set a new signer for the contract
     * @param signer_ Address of the new signer.
     */
    function setSigner(address signer_) external;
}
