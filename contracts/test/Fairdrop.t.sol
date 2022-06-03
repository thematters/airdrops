// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'forge-std/Vm.sol';
import 'forge-std/console2.sol';

import './utils/ERC20Token.sol';

import '../Fairdrop.sol';

contract FairdropTest is Test {
    using ECDSA for bytes32;

    ERC20Token public token;
    Fairdrop public fairdrop;

    uint256 public constant OWNER_PK = 174;
    uint256 public constant SIGNER_PK = 175;
    uint256 public constant DEPLOYER_PK = 176;
    uint256 public constant CLAIMER_PK = 177;
    uint256 public constant CLAIMER2_PK = 178;
    address public owner;
    address public signer;
    address public deployer;
    address public claimer;
    address public claimer2;

    bytes32 public constant USER_ID = keccak256('twitter:1234567890');
    bytes32 public constant USER_ID_2 = keccak256('twitter:1234567891');

    uint256 public constant FAIRDROP_BALANCE = 100000e18;
    uint256 public constant AMOUNT_PER_ADDRESS = 10e18;

    uint256 public constant EXPIRED_AT = 1648720000;
    string public constant NONCE = '74b0b972408bb0b4858a6b2b';

    function setUp() public virtual {
        // init addresses
        owner = vm.addr(OWNER_PK);
        signer = vm.addr(SIGNER_PK);
        deployer = vm.addr(DEPLOYER_PK);
        claimer = vm.addr(CLAIMER_PK);
        vm.label(owner, 'owner');
        vm.label(signer, 'signer');
        vm.label(deployer, 'deployer');
        vm.label(claimer, 'claimer');

        vm.startPrank(deployer);

        // Deploy ERC-20 token
        token = new ERC20Token();

        // Deploy fairdrop contract
        fairdrop = new Fairdrop(address(token), signer, owner, AMOUNT_PER_ADDRESS);

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
        bytes32 hash = keccak256(abi.encode(account_, userId_, NONCE, expiredAt_, address(fairdrop)))
            .toEthSignedMessageHash();

        (v, r, s) = vm.sign(SIGNER_PK, hash);
    }

    function testClaim() public {
        (uint8 v, bytes32 r, bytes32 s) = _perimt(claimer, USER_ID, EXPIRED_AT);

        uint256 prevBalance = token.balanceOf(claimer);
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);
        assertEq(token.balanceOf(claimer), prevBalance + AMOUNT_PER_ADDRESS);
    }

    function testCannotClaimTwiceWithSameUserId() public {
        // first claim

        (uint8 v, bytes32 r, bytes32 s) = _perimt(claimer, USER_ID, EXPIRED_AT);
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);

        // second claim
        vm.expectRevert(abi.encodeWithSignature('UserIdAlreadyClaimed(bytes32)', USER_ID));
        (uint8 v2, bytes32 r2, bytes32 s2) = _perimt(claimer2, USER_ID, EXPIRED_AT);
        fairdrop.claim(claimer2, USER_ID, NONCE, EXPIRED_AT, v2, r2, s2);
    }

    function testCannotClaimTwiceWithSameAddress() public {
        // first claim

        (uint8 v, bytes32 r, bytes32 s) = _perimt(claimer, USER_ID, EXPIRED_AT);
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);

        // second claim
        vm.expectRevert(abi.encodeWithSignature('AddressAlreadyClaimed(address)', claimer));
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);
    }

    function testCannotClaimWithWrongSignature() public {
        // sign with wrong account
        (uint8 v, bytes32 r, bytes32 s) = _perimt(claimer2, USER_ID, EXPIRED_AT);
        vm.expectRevert(abi.encodeWithSignature('InvalidSignature()'));
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);
    }

    function testCannotClaimExpired() public {
        (uint8 v, bytes32 r, bytes32 s) = _perimt(claimer, USER_ID, EXPIRED_AT);

        vm.expectRevert(abi.encodeWithSignature('ClaimExpired()'));
        vm.warp(EXPIRED_AT + 1);
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);
    }

    function testSetAmountPerAddress() public {
        uint256 newAmountPerAddress = AMOUNT_PER_ADDRESS + 100;

        // set amount per address
        vm.prank(owner);
        fairdrop.setAmountPerAddress(newAmountPerAddress);

        // claim

        (uint8 v, bytes32 r, bytes32 s) = _perimt(claimer, USER_ID, EXPIRED_AT);

        uint256 prevBalance = token.balanceOf(claimer);
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);
        assertEq(token.balanceOf(claimer), prevBalance + newAmountPerAddress);
    }

    function testCannotSetAmountPerAddressByNonOwner() public {
        vm.expectRevert('Ownable: caller is not the owner');
        fairdrop.setAmountPerAddress(1);
    }

    /**
     * Withdraw
     */
    function testCannotSweepByNonOwner() public {
        vm.expectRevert('Ownable: caller is not the owner');
        fairdrop.sweep(owner);
    }

    function testSweep() public {
        uint256 fairdropBalance = token.balanceOf(address(fairdrop));
        uint256 ownerBalance = token.balanceOf(owner);

        vm.prank(owner);
        fairdrop.sweep(owner);

        // airdrop balance should be 0
        assertEq(token.balanceOf(address(fairdrop)), 0);

        // owner balance should be increased
        assertEq(token.balanceOf(owner), ownerBalance + fairdropBalance);
    }

    function testSweepToOwner() public {
        uint256 fairdropBalance = token.balanceOf(address(fairdrop));
        uint256 ownerBalance = token.balanceOf(owner);

        fairdrop.sweepToOwner();

        // fairdrop balance should be 0
        assertEq(token.balanceOf(address(fairdrop)), 0);

        // deployer balance should be increased
        assertEq(token.balanceOf(owner), ownerBalance + fairdropBalance);
    }

    /**
     * Verify
     */
    function testSetSigner() public {
        uint256 newSignerPk = SIGNER_PK + 1000;
        address newSigner = vm.addr(newSignerPk);

        bytes32 hash = keccak256(abi.encode(claimer, USER_ID, NONCE, EXPIRED_AT, address(fairdrop)))
            .toEthSignedMessageHash();

        // set new signer
        vm.prank(owner);
        fairdrop.setSigner(newSigner);

        // claim with new signer pk
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(newSignerPk, hash);
        fairdrop.claim(claimer, USER_ID, NONCE, EXPIRED_AT, v, r, s);

        // cannot claim with old signer pk
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(SIGNER_PK, hash);
        vm.expectRevert(abi.encodeWithSignature('InvalidSignature()'));
        fairdrop.claim(claimer2, USER_ID_2, NONCE, EXPIRED_AT, v2, r2, s2);
    }

    function testCannotSetSignerByNonOwner() public {
        vm.expectRevert('Ownable: caller is not the owner');
        fairdrop.setSigner(claimer);
    }
}
