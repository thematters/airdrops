// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract TheSpaceClaimAirdrop {
    bytes32 public merkleRoot;

    constructor(bytes32 merkleRoot_) {
        merkleRoot = merkleRoot_;
    }
}
