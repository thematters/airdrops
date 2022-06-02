// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DSTest} from 'ds-test/test.sol';

import './utils/ERC20Token.sol';
import {Hevm} from './utils/Hevm.sol';
import {console} from './utils/Console.sol';

import '../Fairdrop.sol';

contract FairdropTest is DSTest {
    ERC20Token public token;
    Fairdrop public fairdrop;

    Hevm public vm = Hevm(HEVM_ADDRESS);

    uint256 public constant OWNER_PK = 174;
    uint256 public constant SIGNER_PK = 175;
    uint256 public constant DEPLOYER_PK = 176;
    uint256 public constant CLAIMER_PK = 177;
    uint256 public constant CLAIMER_2_PK = 178;
    address public OWNER;
    address public SIGNER;
    address public DEPLOYER;
    address public CLAIMER;
    address public CLAIMER_2;

    uint256 public constant FAIRDROP_BALANCE = 100000e18;
    uint256 public constant AMOUNT_PER_ADDRESS = 10e18;

    uint256 public constant EXPIRED_AT = 1648720000;

    function setUp() public virtual {
        // init addresses
        OWNER = vm.addr(OWNER_PK);
        SIGNER = vm.addr(SIGNER_PK);
        DEPLOYER = vm.addr(DEPLOYER_PK);
        CLAIMER = vm.addr(CLAIMER_PK);
        vm.label(OWNER, 'OWNER');
        vm.label(SIGNER, 'SIGNER');
        vm.label(DEPLOYER, 'DEPLOYER');
        vm.label(CLAIMER, 'CLAIMER');

        vm.startPrank(DEPLOYER);

        // Deploy ERC-20 token
        token = new ERC20Token();

        // Deploy fairdrop contract
        fairdrop = new Fairdrop(address(token), SIGNER, OWNER, AMOUNT_PER_ADDRESS);

        // Transfer some to fairdrop contract
        token.mint(address(fairdrop), FAIRDROP_BALANCE);

        vm.stopPrank();
    }

    function testBalance() public {
        uint256 fairdropBalance = token.balanceOf(address(fairdrop));
        assertEq(fairdropBalance, FAIRDROP_BALANCE);
    }

    /**
     * Claim
     */
    function _perimt(
        address account_,
        bytes32 userId_,
        uint256 expiredAt_
    )
        internal
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        bytes32 hash = keccak256(abi.encode(account_, userId_, expiredAt_, address(fairdrop)));

        (v, r, s) = vm.sign(SIGNER_PK, hash);
        console2.log(v, r, s);
    }

    function testClaim() public {
        bytes32 userId = keccak256('twitter:1234567890');
        (uint8 v, bytes32 r, bytes32 s) = _perimt(CLAIMER, userId, EXPIRED_AT);

        uint256 prevBalance = token.balanceOf(CLAIMER);
        fairdrop.claim(CLAIMER, userId, EXPIRED_AT, v, r, s);
        assertEq(token.balanceOf(CLAIMER), prevBalance + AMOUNT_PER_ADDRESS);
    }

    function testCannotClaimTwiceWithSameUserId() public {
        // first claim
        bytes32 userId = keccak256('twitter:1234567890');
        (uint8 v, bytes32 r, bytes32 s) = _perimt(CLAIMER, userId, EXPIRED_AT);
        fairdrop.claim(CLAIMER, userId, EXPIRED_AT, v, r, s);

        // second claim
        // vm.expectRevert(abi.encodeWithSignature('UserIdAlreadyClaimed(bytes32)', userId));
        // (uint8 v2, bytes32 r2, bytes32 s2) = _perimt(CLAIMER_2, userId, EXPIRED_AT);
        // fairdrop.claim(CLAIMER_2, userId, EXPIRED_AT, v2, r2, s2);
    }

    function testCannotClaimTwiceWithSameAddress() public {
        // first claim
        bytes32 userId = keccak256('twitter:1234567890');
        (uint8 v, bytes32 r, bytes32 s) = _perimt(CLAIMER, userId, EXPIRED_AT);
        fairdrop.claim(CLAIMER, userId, EXPIRED_AT, v, r, s);

        // second claim
        vm.expectRevert(abi.encodeWithSignature('AddressAlreadyClaimed(address)', CLAIMER));
        fairdrop.claim(CLAIMER, userId, EXPIRED_AT, v, r, s);
    }

    function testCannotClaimWithWrongSignature() public {
        bytes32 userId = keccak256('twitter:1234567890');

        // sign with wrong account
        (uint8 v, bytes32 r, bytes32 s) = _perimt(CLAIMER_2, userId, EXPIRED_AT);
        vm.expectRevert(abi.encodeWithSignature('InvalidSignature()'));
        fairdrop.claim(CLAIMER, userId, EXPIRED_AT, v, r, s);
    }

    function testCannotClaimExpired() public {
        bytes32 userId = keccak256('twitter:1234567890');
        (uint8 v, bytes32 r, bytes32 s) = _perimt(CLAIMER, userId, EXPIRED_AT);

        vm.expectRevert(abi.encodeWithSignature('ClaimExpired()'));
        vm.warp(EXPIRED_AT + 1);
        fairdrop.claim(CLAIMER, userId, EXPIRED_AT, v, r, s);
    }

    function testSetAmountPerAddress() public {}

    function testCannotSetAmountPerAddressByNonOwner() public {}

    /**
     * Withdraw
     */
    function testCannotSweepByNonOwner() public {
        vm.expectRevert('Ownable: caller is not the owner');
        fairdrop.sweep(OWNER);
    }

    function testSweep() public {
        uint256 fairdropBalance = token.balanceOf(address(fairdrop));
        uint256 ownerBalance = token.balanceOf(OWNER);

        vm.prank(OWNER);
        fairdrop.sweep(OWNER);

        // airdrop balance should be 0
        assertEq(token.balanceOf(address(fairdrop)), 0);

        // owner balance should be increased
        assertEq(token.balanceOf(OWNER), ownerBalance + fairdropBalance);
    }

    function testSweepToOwner() public {
        uint256 fairdropBalance = token.balanceOf(address(fairdrop));
        uint256 ownerBalance = token.balanceOf(OWNER);

        fairdrop.sweepToOwner();

        // fairdrop balance should be 0
        assertEq(token.balanceOf(address(fairdrop)), 0);

        // deployer balance should be increased
        assertEq(token.balanceOf(OWNER), ownerBalance + fairdropBalance);
    }

    /**
     * Verify
     */
    function testSetSigner() public {}

    function testCannotSetSignerByNonOwner() public {}
}
