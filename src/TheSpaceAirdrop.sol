// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./MerkleDistributor.sol";

contract TheSpaceAirdrop is MerkleDistributor {
    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 expiredAt_
    ) MerkleDistributor(token_, merkleRoot_, expiredAt_) {}
}
