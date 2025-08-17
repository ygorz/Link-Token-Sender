// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {LinkTokenSender} from "../src/LinkTokenSender.sol";
import {LinkToken} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/LinkToken.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract LinkTokenSenderTest is Test {
    LinkTokenSender public linkTokenSender;
    LinkTokenSender public linkTokenSenderOnSepolia;
    LinkToken public mockLinkToken;
    address public ccipRouterAddress = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    LinkTokenInterface public linkTokenInterface;

    CCIPLocalSimulatorFork public ccipSimulator;

    address public USER = makeAddr("USER");
    address public RECEIVING_ADDRESS1 = makeAddr("RECEIVING_ADDRESS1");
    address public RECEIVING_ADDRESS2 = makeAddr("RECEIVING_ADDRESS2");
    address public RECEIVING_ADDRESS3 = makeAddr("RECEIVING_ADDRESS3");
    address public RECEIVING_ADDRESS4 = makeAddr("RECEIVING_ADDRESS4");
    address public RECEIVING_ADDRESS5 = makeAddr("RECEIVING_ADDRESS5");

    function setUp() public {
        mockLinkToken = new LinkToken();
        linkTokenSender = new LinkTokenSender(address(mockLinkToken), ccipRouterAddress);
    }

    function testSendLinkCrossChain() public {}
}
