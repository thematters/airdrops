// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DSTest} from 'ds-test/test.sol';
import '../MerkleDistributor.sol';
import './utils/ERC20Token.sol';
import {Hevm} from './utils/Hevm.sol';
import {console} from './utils/Console.sol';

contract MerkleDistributorTest is DSTest {
    ERC20Token private token;
    MerkleDistributor private distributor;

    Hevm constant vm = Hevm(HEVM_ADDRESS);

    address constant DEPLOYER = address(175);
    uint256 constant DEPLOYER_BALANCE = 100000e18;

    uint256 constant EXPIRED_AT = 1648720000;

    bytes32 constant MERKLE_ROOT = 0xfc509a132749bf3defdee8950c44a9a83962d004f83c078c258dd3654fc540f2;

    function setUp() public virtual {
        vm.label(DEPLOYER, 'DEPLOYER');

        vm.startPrank(DEPLOYER);

        // Create token
        token = new ERC20Token();

        // Create merkle distributor
        distributor = new MerkleDistributor(address(token), MERKLE_ROOT, EXPIRED_AT);

        // Transfer token to distributor
        token.mint(address(distributor), DEPLOYER_BALANCE);

        vm.stopPrank();
    }

    function testBalance() public {
        uint256 distributorBalance = token.balanceOf(address(distributor));
        assertEq(distributorBalance, DEPLOYER_BALANCE);
    }

    function _claim(
        address account,
        uint256 amount,
        bytes32[] memory merkleProof
    ) private {
        vm.deal(account, 0);
        distributor.claim(account, amount, merkleProof);
        assertEq(token.balanceOf(account), amount);
    }

    function testClaim() public {
        // Alice claims 100 $TOKEN
        address ALICE = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        vm.label(ALICE, 'ALICE');
        bytes32[] memory aliceProof = new bytes32[](3);
        aliceProof[0] = 0x98bb949ca75e092f3e9c8e09d23063c64698f36937c6d2fe9c2144b8c4a1fbc2;
        aliceProof[1] = 0xe34ddb23ff40befd09095e53709edf85520e770273dab8b857fc60c68727003f;
        aliceProof[2] = 0x28f666abe594c6468cd5a251dd392713c3f01d0488c2598c3d0b72522aadf6ae;
        _claim(ALICE, 10e18, aliceProof);

        // Bob claims 0.32 $TOKEN
        address BOB = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
        vm.label(BOB, 'BOB');
        bytes32[] memory bobProof = new bytes32[](3);
        bobProof[0] = 0xd6ece33a93a757f3cb9ca7a599fa2f6912463168769e67e829ea5ba6b096e7b1;
        bobProof[1] = 0xe9530c925ead67ccd6c1c0b030ac7c15dfd76187946cdcf4ea3807650df62e91;
        bobProof[2] = 0x28f666abe594c6468cd5a251dd392713c3f01d0488c2598c3d0b72522aadf6ae;
        _claim(BOB, 32e16, bobProof);
    }

    function testFailClaim() public {
        // Charlie claims 100 $TOKEN
        address CHARLIE = 0x7f268357A8c2552623316e2562D90e642bB538E5;
        vm.label(CHARLIE, 'CHARLIE');

        // wrong proof
        bytes32[] memory charlieProof = new bytes32[](3);
        charlieProof[0] = 0x98bb949ca75e092f3e9c8e09d23063c64698f36937c6d2fe9c2144b8c4a1fbc2;
        charlieProof[1] = 0xe34ddb23ff40befd09095e53709edf85520e770273dab8b857fc60c68727003f;
        charlieProof[2] = 0x28f666abe594c6468cd5a251dd392713c3f01d0488c2598c3d0b72522aadf6ae;

        _claim(CHARLIE, 10e18, charlieProof);
    }
}
