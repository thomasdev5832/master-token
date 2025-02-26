// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MasterToken} from "../src/MasterToken.sol";

contract MasterTokenTest is Test {
    MasterToken public masterToken;
    address public owner;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public newOwner = address(0x3);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    // Chaves para teste de permit (exemplo, em produção use uma carteira real)
    uint256 private constant OWNER_PRIVATE_KEY = 0xabc123;

    function setUp() public {
        masterToken = new MasterToken("MasterToken", "MTK");
        owner = address(this);
    }

    /// @notice Test initial token supply
    function testInitialSupply() public view {
        assertEq(masterToken.totalSupply(), 1000000 * 10**18, "Initial supply should be 1M tokens");
    }

    /// @notice Test max supply
    function testMaxSupply() public view {
        assertEq(masterToken.maxSupply(), 10000000 * 10**18, "Max supply should be 10M tokens");
    }

    /// @notice Test initial balance of the owner
    function testInitialBalance() public view {
        assertEq(masterToken.balanceOf(owner), 1000000 * 10**18, "Owner should have 1M tokens");
    }

    /// @notice Test token name
    function testName() public view {
        assertEq(masterToken.name(), "MasterToken", "Name should be MasterToken");
    }

    /// @notice Test token symbol
    function testSymbol() public view {
        assertEq(masterToken.symbol(), "MTK", "Symbol should be MTK");
    }

    /// @notice Test token decimals
    function testDecimals() public view {
        assertEq(masterToken.decimals(), 18, "Decimals should be 18");
    }

    /// @notice Test successful token transfer
    function testTransfer() public {
        uint256 amount = 1000 * 10**18;
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, amount);
        bool success = masterToken.transfer(user1, amount);
        assertTrue(success, "Transfer should succeed");
        assertEq(masterToken.balanceOf(owner), 999000 * 10**18, "Owner balance should decrease");
        assertEq(masterToken.balanceOf(user1), amount, "User1 balance should increase");
    }

    /// @notice Test transfer with insufficient balance
    function test_RevertIf_InsufficientBalance() public {
        uint256 amount = 2000000 * 10**18;
        vm.expectRevert("Insufficient balance");
        masterToken.transfer(user1, amount);
    }

    /// @notice Test transfer of zero amount
    function testTransferZeroAmount() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, 0);
        bool success = masterToken.transfer(user1, 0);
        assertTrue(success, "Transfer of 0 should succeed");
    }

    /// @notice Test approval
    function testApprove() public {
        uint256 amount = 500 * 10**18;
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, user1, amount);
        bool success = masterToken.approve(user1, amount);
        assertTrue(success, "Approve should succeed");
        assertEq(masterToken.allowance(owner, user1), amount, "Allowance should be set");
    }

    /// @notice Test increase allowance
    function testIncreaseAllowance() public {
        uint256 initialAmount = 500 * 10**18;
        uint256 addedAmount = 200 * 10**18;
        masterToken.approve(user1, initialAmount);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, user1, initialAmount + addedAmount);
        bool success = masterToken.increaseAllowance(user1, addedAmount);
        assertTrue(success, "Increase allowance should succeed");
        assertEq(masterToken.allowance(owner, user1), initialAmount + addedAmount, "Allowance should increase");
    }

    /// @notice Test decrease allowance
    function testDecreaseAllowance() public {
        uint256 initialAmount = 500 * 10**18;
        uint256 subtractedAmount = 200 * 10**18;
        masterToken.approve(user1, initialAmount);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, user1, initialAmount - subtractedAmount);
        bool success = masterToken.decreaseAllowance(user1, subtractedAmount);
        assertTrue(success, "Decrease allowance should succeed");
        assertEq(masterToken.allowance(owner, user1), initialAmount - subtractedAmount, "Allowance should decrease");
    }

    /// @notice Test decrease allowance below zero
    function test_RevertIf_DecreaseAllowanceUnderflow() public {
        uint256 initialAmount = 500 * 10**18;
        masterToken.approve(user1, initialAmount);
        vm.expectRevert("Allowance underflow");
        masterToken.decreaseAllowance(user1, initialAmount + 1);
    }

     /// @notice Test permit (EIP-712)
    function testPermit() public {
        uint256 amount = 500 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;
        address permitOwner = vm.addr(OWNER_PRIVATE_KEY);

        // Transferir tokens para permitOwner para teste
        masterToken.transfer(permitOwner, 1000 * 10**18);

        // Gerar assinatura off-chain
        bytes32 structHash = keccak256(
            abi.encode(
                masterToken.PERMIT_TYPEHASH(),
                permitOwner,
                user1,
                amount,
                0, // nonce inicial
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", masterToken.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PRIVATE_KEY, digest);

        // Executar permit
        vm.expectEmit(true, true, false, true);
        emit Approval(permitOwner, user1, amount);
        masterToken.permit(permitOwner, user1, amount, deadline, v, r, s);

        assertEq(masterToken.allowance(permitOwner, user1), amount, "Allowance should be set");
        assertEq(masterToken.nonces(permitOwner), 1, "Nonce should increment");
    }

    /// @notice Test permit with invalid signature
    function test_RevertIf_InvalidPermitSignature() public {
        uint256 amount = 500 * 10**18;
        uint256 deadline = block.timestamp + 1 hours;
        address permitOwner = vm.addr(OWNER_PRIVATE_KEY);
        masterToken.transfer(permitOwner, 1000 * 10**18);

        // Assinatura inválida (nonce errado)
        bytes32 structHash = keccak256(
            abi.encode(masterToken.PERMIT_TYPEHASH(), permitOwner, user1, amount, 1, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", masterToken.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PRIVATE_KEY, digest);

        vm.expectRevert("Invalid signature");
        masterToken.permit(permitOwner, user1, amount, deadline, v, r, s);
    }

    /// @notice Test permit expired
    function test_RevertIf_PermitExpired() public {
        uint256 amount = 500 * 10**18;
        uint256 deadline = block.timestamp - 1; // Já expirado
        address permitOwner = vm.addr(OWNER_PRIVATE_KEY);
        masterToken.transfer(permitOwner, 1000 * 10**18);

        bytes32 structHash = keccak256(
            abi.encode(masterToken.PERMIT_TYPEHASH(), permitOwner, user1, amount, 0, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", masterToken.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(OWNER_PRIVATE_KEY, digest);

        vm.expectRevert("Permit expired");
        masterToken.permit(permitOwner, user1, amount, deadline, v, r, s);
    }

    /// @notice Test transferFrom
    function testTransferFrom() public {
        uint256 amount = 300 * 10**18;
        masterToken.approve(user1, amount);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user2, amount);
        bool success = masterToken.transferFrom(owner, user2, amount);
        assertTrue(success, "TransferFrom should succeed");
        assertEq(masterToken.balanceOf(owner), 999700 * 10**18, "Owner balance should decrease");
        assertEq(masterToken.balanceOf(user2), amount, "User2 balance should increase");
        assertEq(masterToken.allowance(owner, user1), 0, "Allowance should be consumed");
    }

    /// @notice Test transferFrom with insufficient allowance
    function test_RevertIf_InsufficientAllowance() public {
        uint256 amount = 300 * 10**18;
        masterToken.approve(user1, amount - 1);
        vm.prank(user1);
        vm.expectRevert("Insufficient allowance");
        masterToken.transferFrom(owner, user2, amount);
    }

    /// @notice Test minting by owner
    function testMint() public {
        uint256 amount = 100 * 10**18;
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), owner, amount);
        masterToken.mint(owner, amount);
        assertEq(masterToken.totalSupply(), 1000100 * 10**18, "Total supply should increase");
        assertEq(masterToken.balanceOf(owner), 1000100 * 10**18, "Owner balance should increase");
    }

    /// @notice Test minting exceeding max supply
    function test_RevertIf_MintExceedsMaxSupply() public {
        uint256 amount = 10000000 * 10**18; // Mais que o maxSupply - totalSupply
        vm.expectRevert("Exceeds max supply");
        masterToken.mint(owner, amount);
    }

    /// @notice Test minting by non-owner should revert
    function test_RevertIf_MintNotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        masterToken.mint(user1, 100 * 10**18);
    }

    /// @notice Test burn tokens
    function testBurn() public {
        uint256 amount = 100 * 10**18;
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);
        masterToken.burn(amount);
        assertEq(masterToken.totalSupply(), 999900 * 10**18, "Total supply should decrease");
        assertEq(masterToken.balanceOf(owner), 999900 * 10**18, "Owner balance should decrease");
    }

    /// @notice Test burn with insufficient balance
    function test_RevertIf_BurnInsufficientBalance() public {
        vm.expectRevert("Insufficient balance");
        masterToken.burn(2000000 * 10**18);
    }

    /// @notice Test burnFrom
    function testBurnFrom() public {
        uint256 amount = 300 * 10**18;
        masterToken.approve(user1, amount);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);
        masterToken.burnFrom(owner, amount);
        assertEq(masterToken.totalSupply(), 999700 * 10**18, "Total supply should decrease");
        assertEq(masterToken.balanceOf(owner), 999700 * 10**18, "Owner balance should decrease");
        assertEq(masterToken.allowance(owner, user1), 0, "Allowance should be consumed");
    }

    /// @notice Test burnFrom with insufficient allowance
    function test_RevertIf_BurnFromInsufficientAllowance() public {
        uint256 amount = 300 * 10**18;
        masterToken.approve(user1, amount - 1);
        vm.prank(user1);
        vm.expectRevert("Insufficient allowance");
        masterToken.burnFrom(owner, amount);
    }

    /// @notice Test transfer to zero address
    function test_RevertIf_TransferToZeroAddress() public {
        vm.expectRevert("Invalid address");
        masterToken.transfer(address(0), 100 * 10**18);
    }

    /// @notice Test approve to zero address
    function test_RevertIf_ApproveToZeroAddress() public {
        vm.expectRevert("Invalid address");
        masterToken.approve(address(0), 100 * 10**18);
    }

    /// @notice Test transferOwnership
    function testTransferOwnership() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(owner, newOwner);
        masterToken.transferOwnership(newOwner);
        assertEq(masterToken.owner(), newOwner, "Ownership should be transferred");
    }

    /// @notice Test transferOwnership by non-owner should revert
    function test_RevertIf_TransferOwnershipNotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        masterToken.transferOwnership(newOwner);
    }

    /// @notice Test pause functionality
    function testPause() public {
        vm.expectEmit(true, false, false, true);
        emit Paused(owner);
        masterToken.pause();
        assertTrue(masterToken.paused(), "Contract should be paused");
    }

    /// @notice Test transfer when paused should revert
    function test_RevertIf_TransferWhenPaused() public {
        masterToken.pause();
        vm.expectRevert("Contract paused");
        masterToken.transfer(user1, 100 * 10**18);
    }

    /// @notice Test unpause functionality
    function testUnpause() public {
        masterToken.pause();
        vm.expectEmit(true, false, false, true);
        emit Unpaused(owner);
        masterToken.unpause();
        assertFalse(masterToken.paused(), "Contract should be unpaused");
    }
}