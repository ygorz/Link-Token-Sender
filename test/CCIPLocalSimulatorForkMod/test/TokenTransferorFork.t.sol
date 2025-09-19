// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, Vm} from "forge-std/Test.sol";
import {TokenTransferor} from "lib/chainlink-local/src/test/ccip/TokenTransferor.sol";
import {BurnMintERC677Helper} from "lib/chainlink-local/src/ccip/BurnMintERC677Helper.sol";
import {IERC20} from
    "lib/chainlink-local/lib/chainlink-evm/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {CCIPLocalSimulatorForkUMV, Register} from "test/CCIPLocalSimulatorForkMod/CCIPLocalSimulatorForkUMV.sol";

contract TokenTransferorForkUMV is Test {
    CCIPLocalSimulatorForkUMV public ccipLocalSimulatorFork;
    TokenTransferor public sender;
    BurnMintERC677Helper public ccipBnM;
    IERC20 public linkToken;
    address alice;

    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    function setUp() public {
        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
        sepoliaFork = vm.createSelectFork(ETHEREUM_SEPOLIA_RPC_URL);
        arbSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorForkUMV();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        Register.NetworkDetails memory sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        sender = new TokenTransferor(sepoliaNetworkDetails.routerAddress, sepoliaNetworkDetails.linkAddress);

        ccipBnM = BurnMintERC677Helper(sepoliaNetworkDetails.ccipBnMAddress);

        linkToken = IERC20(sepoliaNetworkDetails.linkAddress);

        alice = makeAddr("alice");

        ccipLocalSimulatorFork.requestLinkFromFaucet(address(sender), 25 ether);
    }

    function test_forkTokenTransfer() external {
        uint256 amountToSend = 100;
        ccipBnM.drip(address(sender));

        uint64 arbSepoliaChainSelector = 3478487238524512106;
        sender.allowlistDestinationChain(arbSepoliaChainSelector, true);

        uint256 balanceBefore = ccipBnM.balanceOf(address(sender));

        sender.transferTokensPayLINK(arbSepoliaChainSelector, alice, address(ccipBnM), amountToSend);

        uint256 balanceAfer = ccipBnM.balanceOf(address(sender));
        assertEq(balanceAfer, balanceBefore - amountToSend);

        ccipLocalSimulatorFork.switchSingleChainRouteAllDestMessages(arbSepoliaFork);

        Register.NetworkDetails memory arbSepoliaNetworkDetails =
            ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        BurnMintERC677Helper ccipBnMArbSepolia = BurnMintERC677Helper(arbSepoliaNetworkDetails.ccipBnMAddress);

        assertEq(ccipBnMArbSepolia.balanceOf(alice), amountToSend);
    }
}
