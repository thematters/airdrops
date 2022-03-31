// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DSTest} from "ds-test/test.sol";
import "../MerkleDistributor.sol";
import "./utils/ERC20Token.sol";
import {Hevm} from "./utils/Hevm.sol";
import {console} from "./utils/Console.sol";

contract MerkleDistributorTest is DSTest {
    ERC20Token private token;
    MerkleDistributor private distributor;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(175);
    address constant ALICE = address(176);
    address constant BOB = address(177);
    address constant CHARLIE = address(178);

    uint256 constant EXPIRED_AT = 1648720000;

    uint256 constant BALANCE_DEPLOYER = 1000;
    uint256 constant BALANCE_ALICE = 20;
    uint256 constant BALANCE_BOB = 200;
    uint256 constant BALANCE_CHARLIE = 12;

    function setUp() public virtual {
        vm.label(DEPLOYER, "DEPLOYER");
        vm.startPrank(DEPLOYER);

        // Create token
        token = new ERC20Token();

        // Create merkle distributor
        distributor = new MerkleDistributor(address(token), "..", EXPIRED_AT);

        // Transfer token to distributor
        token.mint(address(distributor), BALANCE_DEPLOYER);

        vm.stopPrank();
    }

    function testBalance() public {
        uint256 distributorBalance = token.balanceOf(address(distributor));
        assertEq(distributorBalance, BALANCE_DEPLOYER);
    }
}
