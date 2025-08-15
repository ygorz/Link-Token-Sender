// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {LinkTokenSender} from "../src/LinkTokenSender.sol";
import {LinkToken} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/LinkToken.sol";

contract LinkTokenSenderTest is Test {
    LinkTokenSender public linkTokenSender;
    LinkToken public mockLinkToken;

    address public USER = makeAddr("USER");
    address public RECEIVING_ADDRESS1 = makeAddr("RECEIVING_ADDRESS1");
    address public RECEIVING_ADDRESS2 = makeAddr("RECEIVING_ADDRESS2");
    address public RECEIVING_ADDRESS3 = makeAddr("RECEIVING_ADDRESS3");
    address public RECEIVING_ADDRESS4 = makeAddr("RECEIVING_ADDRESS4");
    address public RECEIVING_ADDRESS5 = makeAddr("RECEIVING_ADDRESS5");

    function setUp() public {
        mockLinkToken = new LinkToken();
        linkTokenSender = new LinkTokenSender(address(mockLinkToken));
    }

    function testSendLink() public {
        // Arrange
        uint256 amountToSend = 1 ether;

        address[] memory addressesToReceive = new address[](1);
        addressesToReceive[0] = RECEIVING_ADDRESS1;

        uint256[] memory amountsToSend = new uint256[](1);
        amountsToSend[0] = amountToSend;

        // Mint LINK tokens to the sender
        mockLinkToken.grantMintRole(address(this));
        mockLinkToken.mint(USER, 10 ether);

        // Approve LinkTokenSender to spend USER's tokens
        vm.startPrank(USER);
        mockLinkToken.approve(address(linkTokenSender), 10 ether);

        // Act
        linkTokenSender.sendLink(addressesToReceive, amountsToSend);
        vm.stopPrank();

        // Assert
        assertEq(mockLinkToken.balanceOf(USER), 9 ether, "USER balance should be 9 ether after transfer");
        assertEq(mockLinkToken.balanceOf(RECEIVING_ADDRESS1), amountToSend, "RECEIVING_ADDRESS should receive 1 ether");
    }

    function testSendLinkToMultipleReceiversAndValues() public {
        // Arrange
        uint256 amountToSend1 = 1 ether;
        uint256 amountToSend2 = 2 ether;
        uint256 amountToSend3 = 1.5 ether;
        uint256 amountToSend4 = 1.1 ether;
        uint256 amountToSend5 = 2.1 ether;

        address[] memory addressesToReceive = new address[](5);
        addressesToReceive[0] = RECEIVING_ADDRESS1;
        addressesToReceive[1] = RECEIVING_ADDRESS2;
        addressesToReceive[2] = RECEIVING_ADDRESS3;
        addressesToReceive[3] = RECEIVING_ADDRESS4;
        addressesToReceive[4] = RECEIVING_ADDRESS5;

        uint256[] memory amountsToSend = new uint256[](5);
        amountsToSend[0] = amountToSend1;
        amountsToSend[1] = amountToSend2;
        amountsToSend[2] = amountToSend3;
        amountsToSend[3] = amountToSend4;
        amountsToSend[4] = amountToSend5;

        // Mint LINK tokens to the sender
        mockLinkToken.grantMintRole(address(this));
        mockLinkToken.mint(USER, 100 ether);

        // Approve LinkTokenSender to spend USER's tokens
        vm.startPrank(USER);
        mockLinkToken.approve(address(linkTokenSender), 100 ether);

        // Act
        linkTokenSender.sendLink(addressesToReceive, amountsToSend);
        vm.stopPrank();

        assertEq(mockLinkToken.balanceOf(RECEIVING_ADDRESS1), amountToSend1);
        assertEq(mockLinkToken.balanceOf(RECEIVING_ADDRESS2), amountToSend2);
        assertEq(mockLinkToken.balanceOf(RECEIVING_ADDRESS3), amountToSend3);
        assertEq(mockLinkToken.balanceOf(RECEIVING_ADDRESS4), amountToSend4);
        assertEq(mockLinkToken.balanceOf(RECEIVING_ADDRESS5), amountToSend5);
    }
}
