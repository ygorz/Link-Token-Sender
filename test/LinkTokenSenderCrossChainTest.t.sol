// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {LinkTokenSender} from "src/LinkTokenSender.sol";
import {IERC20} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {CCIPLocalSimulatorForkUMV, Register} from "test/CCIPLocalSimulatorForkMod/CCIPLocalSimulatorForkUMV.sol";

// Not currently used
import {DeployLinkTokenSender} from "script/DeployLinkTokenSender.s.sol";
import {IRouterClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";

contract LinkTokenSenderCrossChainTest is Test {
    LinkTokenSender public linkTokenSender;
    CCIPLocalSimulatorForkUMV public ccipLocalSimulatorFork;

    uint256 public ethereumMainnetForkId;
    uint256 public baseMainnetForkId;

    Register.NetworkDetails public ethMainnetNetworkDetails;
    Register.NetworkDetails public baseMainnetNetworkDetails;

    address public USER = makeAddr("USER");
    address public RECEIVING_ADDRESS1 = makeAddr("RECEIVING_ADDRESS1");

    uint256 public constant LINK_TO_REQUEST = 10e18;
    uint256 public constant LINK_TO_SEND = 1e18;

    function setUp() public {
        // Create forks of both networks
        string memory ETHEREUM_MAINNET_RPC_URL = vm.envString("ETH_MAINNET_RPC_URL");
        string memory BASE_MAINNET_RPC_URL = vm.envString("BASE_MAINNET_RPC_URL");
        ethereumMainnetForkId = vm.createFork(ETHEREUM_MAINNET_RPC_URL);
        baseMainnetForkId = vm.createFork(BASE_MAINNET_RPC_URL);

        console2.log("Eth Mainnet Fork: ", ethereumMainnetForkId); // Fork ID != Chain Id
        console2.log("Base Mainnet Fork: ", baseMainnetForkId); // Fork ID != Chain Id

        // CCIP 1. Create CCIP local simulator fork
        ccipLocalSimulatorFork = new CCIPLocalSimulatorForkUMV();

        // CCIP 2. Add networks to CCIP simulator
        // -> Add ETH mainnet
        ccipLocalSimulatorFork.setNetworkDetails(
            1, // Eth Mainnet Chain ID
            Register.NetworkDetails({
                chainSelector: 5009297550715157269,
                routerAddress: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
                linkAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
                wrappedNativeAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
                registryModuleOwnerCustomAddress: 0x4855174E9479E211337832E109E7721d43A4CA64,
                tokenAdminRegistryAddress: 0xb22764f98dD05c789929716D677382Df22C05Cb6
            })
        );
        // -> Add Base Mainnet
        ccipLocalSimulatorFork.setNetworkDetails(
            8453, // Base Mainnet Chain ID
            Register.NetworkDetails({
                chainSelector: 15971525489660198786,
                routerAddress: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
                linkAddress: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
                wrappedNativeAddress: 0x4200000000000000000000000000000000000006,
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: 0xC842c69d54F83170C42C4d556B4F6B2ca53Dd3E8,
                registryModuleOwnerCustomAddress: 0xAFEd606Bd2CAb6983fC6F10167c98aaC2173D77f,
                tokenAdminRegistryAddress: 0x6f6C373d09C07425BaAE72317863d7F6bb731e37
            })
        );

        // CCIP 3. Make CCIP persistent
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // Get Eth & Base Mainnet Network Details
        vm.selectFork(ethereumMainnetForkId);
        ethMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.selectFork(baseMainnetForkId);
        baseMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        // Request LINK from LINK RESERVE "faux-cet"
        vm.selectFork(ethereumMainnetForkId);
        address linkReserve = 0x9A709B7B69EA42D5eeb1ceBC48674C69E1569eC6; // real address
        vm.prank(linkReserve);
        IERC20(ethMainnetNetworkDetails.linkAddress).transfer(USER, LINK_TO_REQUEST);

        // Deploy LinkTokenSender on Eth Mainnet
        vm.selectFork(ethereumMainnetForkId);
        linkTokenSender =
            new LinkTokenSender(ethMainnetNetworkDetails.linkAddress, ethMainnetNetworkDetails.routerAddress);
    }

    function testSendLinkAndPayLinkCrossChainWorks() public {
        // Check that initial balance of receiving address on Base network is 0
        vm.selectFork(baseMainnetForkId);
        uint256 startingReceiverBalance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS1);
        assertEq(startingReceiverBalance, 0);

        // Check that initial balance of user on Eth mainnet is LINK_TO_REQUEST
        vm.selectFork(ethereumMainnetForkId);
        uint256 startingSenderBalance = IERC20(ethMainnetNetworkDetails.linkAddress).balanceOf(USER);
        assertEq(startingSenderBalance, LINK_TO_REQUEST);

        // Approve LinkTokenSender to spend LINK tokens with extra for gas fee
        vm.startPrank(USER);
        IERC20(ethMainnetNetworkDetails.linkAddress).approve(address(linkTokenSender), LINK_TO_SEND * 2); // Approve double the amount to cover fees

        // Send LINK tokens cross-chain through Link Token Sender contract
        linkTokenSender.sendLinkCrossChain(RECEIVING_ADDRESS1, LINK_TO_SEND, baseMainnetNetworkDetails.chainSelector);
        vm.stopPrank();

        // Have CCIP switch chains and route the message
        ccipLocalSimulatorFork.switchSingleChainRouteAllDestMessages(baseMainnetForkId);

        // Check the USER has less LINK after sending
        // NEEDS WORK HERE!

        // Verify the LINK balance of the receiving address on the base network
        vm.selectFork(baseMainnetForkId);
        uint256 receivingBalance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS1);
        assertEq(receivingBalance, LINK_TO_SEND);
    }
}
