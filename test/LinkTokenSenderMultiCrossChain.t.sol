// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {console2, Test, Vm} from "forge-std/Test.sol";
import {LinkTokenSender} from "src/LinkTokenSender.sol";
import {IERC20} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {CCIPLocalSimulatorForkUMV, Register} from "test/CCIPLocalSimulatorForkMod/CCIPLocalSimulatorForkUMV.sol";
import {IRouter} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouter.sol";
import {Client} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";

contract LinkTokenSenderMultiCrossChainTest is Test {
    LinkTokenSender public linkTokenSender;
    CCIPLocalSimulatorForkUMV public ccipLocalSimulatorFork;

    uint256 public ethereumMainnetForkId;
    uint256 public baseMainnetForkId;
    uint256 public roninMainnetForkId;
    uint256 public scrollMainnetForkId;
    uint256 public soneiumMainnetForkId;
    uint256 public zksyncMainnetForkId;

    Register.NetworkDetails public ethMainnetNetworkDetails;
    Register.NetworkDetails public baseMainnetNetworkDetails;
    Register.NetworkDetails public roninMainnetNetworkDetails;
    Register.NetworkDetails public scrollMainnetNetworkDetails;
    Register.NetworkDetails public soneiumMainnetNetworkDetails;
    // Register.NetworkDetails public zksyncMainnetNetworkDetails;

    address public USER = makeAddr("USER");
    address public RECEIVING_ADDRESS1 = makeAddr("RECEIVING_ADDRESS1");
    address public RECEIVING_ADDRESS2 = makeAddr("RECEIVING_ADDRESS2");
    address public RECEIVING_ADDRESS3 = makeAddr("RECEIVING_ADDRESS3");
    address public RECEIVING_ADDRESS4 = makeAddr("RECEIVING_ADDRESS4");
    // address public RECEIVING_ADDRESS5 = makeAddr("RECEIVING_ADDRESS5");

    uint256 public constant LINK_TO_REQUEST = 100e18;
    uint256 public constant LINK_TO_SEND1 = 1e18;
    uint256 public constant LINK_TO_SEND2 = 2e18;
    uint256 public constant LINK_TO_SEND3 = 3e18;
    uint256 public constant LINK_TO_SEND4 = 4e18;
    // uint256 public constant LINK_TO_SEND5 = 5e18;

    function setUp() public {
        // Create forks of networks
        string memory ETHEREUM_MAINNET_RPC_URL = vm.envString("ETH_MAINNET_RPC_URL");
        string memory BASE_MAINNET_RPC_URL = vm.envString("BASE_MAINNET_RPC_URL");
        string memory RONIN_MAINNET_RPC_URL = vm.envString("RONIN_MAINNET_RPC_URL");
        string memory SCROLL_MAINNET_RPC_URL = vm.envString("SCROLL_MAINNET_RPC_URL");
        string memory SONEIUM_MAINNET_RPC_URL = vm.envString("SONEIUM_MAINNET_RPC_URL");
        // string memory ZKSYNC_MAINNET_RPC_URL = vm.envString("ZKSYNC_MAINNET_RPC_URL");

        ethereumMainnetForkId = vm.createFork(ETHEREUM_MAINNET_RPC_URL);
        baseMainnetForkId = vm.createFork(BASE_MAINNET_RPC_URL);
        roninMainnetForkId = vm.createFork(RONIN_MAINNET_RPC_URL);
        scrollMainnetForkId = vm.createFork(SCROLL_MAINNET_RPC_URL);
        soneiumMainnetForkId = vm.createFork(SONEIUM_MAINNET_RPC_URL);
        // zksyncMainnetForkId = vm.createFork(ZKSYNC_MAINNET_RPC_URL);

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
        // -> Add Ronin mainnet
        ccipLocalSimulatorFork.setNetworkDetails(
            2020, // Ronin Mainnet Chain ID
            Register.NetworkDetails({
                chainSelector: 6916147374840168594,
                routerAddress: 0x46527571D5D1B68eE7Eb60B18A32e6C60DcEAf99,
                linkAddress: 0x3902228D6A3d2Dc44731fD9d45FeE6a61c722D0b,
                wrappedNativeAddress: 0xe514d9DEB7966c8BE0ca922de8a064264eA6bcd4,
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: 0xceA253a8c2BB995054524d071498281E89aACD59,
                registryModuleOwnerCustomAddress: 0x5055DA89A16b71fEF91D1af323b139ceDe2d8320,
                tokenAdminRegistryAddress: 0x90e83d532A4aD13940139c8ACE0B93b0DdbD323a
            })
        );
        // -> Add Scroll mainnet
        ccipLocalSimulatorFork.setNetworkDetails(
            534352, // Scroll Mainnet Chain ID
            Register.NetworkDetails({
                chainSelector: 13204309965629103672,
                routerAddress: 0x9a55E8Cab6564eb7bbd7124238932963B8Af71DC,
                linkAddress: 0x548C6944cba02B9D1C0570102c89de64D258d3Ac,
                wrappedNativeAddress: 0x5300000000000000000000000000000000000004,
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: 0x68B38980aD70650a6f3229BA156e5c1F88A21320,
                registryModuleOwnerCustomAddress: 0x3539F2E214d8BC7E611056383323aC6D1b01943c,
                tokenAdminRegistryAddress: 0x846dEA1c1706FC35b4aa78B32d31F1599DAA47b4
            })
        );
        // -> Add Soneium mainnet
        ccipLocalSimulatorFork.setNetworkDetails(
            1868, // Soneium Mainnet Chain ID
            Register.NetworkDetails({
                chainSelector: 12505351618335765396,
                routerAddress: 0x8C8B88d827Fe14Df2bc6392947d513C86afD6977,
                linkAddress: 0x32D8F819C8080ae44375F8d383Ffd39FC642f3Ec,
                wrappedNativeAddress: 0x4200000000000000000000000000000000000006,
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: 0x3117f515D763652A32d3D6D447171ea7c9d57218,
                registryModuleOwnerCustomAddress: 0x2c3D51c7B454cB045C8cEc92d2F9E717C7519106,
                tokenAdminRegistryAddress: 0x5ba21F6824400B91F232952CA6d7c8875C1755a4
            })
        );
        // -> Add zkSync mainnet
        ccipLocalSimulatorFork.setNetworkDetails(
            324, // zkSync Mainnet Chain ID
            Register.NetworkDetails({
                chainSelector: 1562403441176082196,
                routerAddress: 0x748Fd769d81F5D94752bf8B0875E9301d0ba71bB,
                linkAddress: 0x52869bae3E091e36b0915941577F2D47d8d8B534,
                wrappedNativeAddress: 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91,
                ccipBnMAddress: address(0),
                ccipLnMAddress: address(0),
                rmnProxyAddress: 0x2aBB46A2D32220b8801CE96CAbC32dd2dA7b7B20,
                registryModuleOwnerCustomAddress: 0xab0731056C23b85eDd62F12E716fC75fc1fB1219,
                tokenAdminRegistryAddress: 0x100a47C9DB342884E3314B91cec076BbAC8e619c
            })
        );

        // CCIP 3. Make CCIP persistent
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // Get Mainnet Network Details
        vm.selectFork(ethereumMainnetForkId);
        ethMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.selectFork(baseMainnetForkId);
        baseMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.selectFork(roninMainnetForkId);
        roninMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.selectFork(scrollMainnetForkId);
        scrollMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.selectFork(soneiumMainnetForkId);
        soneiumMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        // vm.selectFork(zksyncMainnetForkId);
        // zksyncMainnetNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        // Request LINK from LINK RESERVE "faux-cet"
        vm.selectFork(ethereumMainnetForkId);
        address linkReserve = 0x9A709B7B69EA42D5eeb1ceBC48674C69E1569eC6; // real address
        vm.prank(linkReserve);
        IERC20(ethMainnetNetworkDetails.linkAddress).transfer(USER, LINK_TO_REQUEST);

        // Deploy LinkTokenSender on Eth Mainnet
        linkTokenSender =
            new LinkTokenSender(ethMainnetNetworkDetails.linkAddress, ethMainnetNetworkDetails.routerAddress);
    }

    function testSendLinkAndPayFeesInLinkToMultipleChains() public {
        // Check that initial balance of USER on Eth mainnet is LINK_TO_REQUEST
        vm.selectFork(ethereumMainnetForkId);
        uint256 startingSenderBalance = IERC20(ethMainnetNetworkDetails.linkAddress).balanceOf(USER);
        assertEq(startingSenderBalance, LINK_TO_REQUEST);

        // Confirm starting balance of each receiving address is 0
        vm.selectFork(baseMainnetForkId);
        uint256 startingReceiver1Balance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS1);
        assertEq(startingReceiver1Balance, 0);

        vm.selectFork(roninMainnetForkId);
        uint256 startingReceiver2Balance = IERC20(roninMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS2);
        assertEq(startingReceiver2Balance, 0);

        vm.selectFork(scrollMainnetForkId);
        uint256 startingReceiver3Balance = IERC20(scrollMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS3);
        assertEq(startingReceiver3Balance, 0);

        vm.selectFork(soneiumMainnetForkId);
        uint256 startingReceiver4Balance =
            IERC20(soneiumMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS4);
        assertEq(startingReceiver4Balance, 0);

        // vm.selectFork(zksyncMainnetForkId);
        // uint256 startingReceiver5Balance = IERC20(zksyncMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS5);
        // assertEq(startingReceiver5Balance, 0);

        vm.selectFork(ethereumMainnetForkId);
        // address[] memory addressesToReceive = new address[](4);
        // addressesToReceive[0] = RECEIVING_ADDRESS1;
        // addressesToReceive[1] = RECEIVING_ADDRESS2;
        // addressesToReceive[2] = RECEIVING_ADDRESS3;
        // addressesToReceive[3] = RECEIVING_ADDRESS4;

        address[] memory addressesToReceive = new address[](8);
        addressesToReceive[0] = RECEIVING_ADDRESS1;
        addressesToReceive[1] = RECEIVING_ADDRESS2;
        addressesToReceive[2] = RECEIVING_ADDRESS3;
        addressesToReceive[3] = RECEIVING_ADDRESS4;
        addressesToReceive[4] = RECEIVING_ADDRESS1;
        addressesToReceive[5] = RECEIVING_ADDRESS2;
        addressesToReceive[6] = RECEIVING_ADDRESS3;
        addressesToReceive[7] = RECEIVING_ADDRESS4;

        uint256[] memory amountsToSend = new uint256[](8);
        amountsToSend[0] = LINK_TO_SEND1;
        amountsToSend[1] = LINK_TO_SEND2;
        amountsToSend[2] = LINK_TO_SEND3;
        amountsToSend[3] = LINK_TO_SEND4;
        amountsToSend[4] = LINK_TO_SEND1;
        amountsToSend[5] = LINK_TO_SEND2;
        amountsToSend[6] = LINK_TO_SEND3;
        amountsToSend[7] = LINK_TO_SEND4;

        uint64[] memory destinationChainSelectors = new uint64[](8);
        // destinationChainSelectors[0] = baseMainnetNetworkDetails.chainSelector; // Base
        // destinationChainSelectors[1] = baseMainnetNetworkDetails.chainSelector; // Base
        // destinationChainSelectors[2] = baseMainnetNetworkDetails.chainSelector; // Base
        // destinationChainSelectors[3] = baseMainnetNetworkDetails.chainSelector; // Base

        destinationChainSelectors[0] = baseMainnetNetworkDetails.chainSelector; // Base
        destinationChainSelectors[1] = baseMainnetNetworkDetails.chainSelector; // Base
        destinationChainSelectors[2] = roninMainnetNetworkDetails.chainSelector; // Ronin
        destinationChainSelectors[3] = roninMainnetNetworkDetails.chainSelector; // Ronin
        destinationChainSelectors[4] = scrollMainnetNetworkDetails.chainSelector; // Scroll
        destinationChainSelectors[5] = scrollMainnetNetworkDetails.chainSelector; // Scroll
        destinationChainSelectors[6] = soneiumMainnetNetworkDetails.chainSelector; // Soneium
        destinationChainSelectors[7] = soneiumMainnetNetworkDetails.chainSelector; // Soneium

        /// ADDED FROM AI ///
        // Start recording logs before the send transaction
        // vm.recordLogs();

        // Approve LinkTokenSender to spend LINK tokens with extra for gas fee
        vm.startPrank(USER);
        IERC20(ethMainnetNetworkDetails.linkAddress).approve(address(linkTokenSender), LINK_TO_REQUEST); // Needs a lot of work, this is very rough

        linkTokenSender.sendLinkMultiCrossChain(addressesToReceive, amountsToSend, destinationChainSelectors);
        vm.stopPrank();

        uint256[] memory forkIds = new uint256[](4);
        forkIds[0] = baseMainnetForkId;
        forkIds[1] = roninMainnetForkId;
        forkIds[2] = scrollMainnetForkId;
        forkIds[3] = soneiumMainnetForkId;
        vm.selectFork(ethereumMainnetForkId);
        ccipLocalSimulatorFork.switchMultiChainRouteAllDestMessages(forkIds);

        // Have CCIP switch chains and route the message
        //ccipLocalSimulatorFork.switchChainAndRouteMessage(baseMainnetForkId);
        //vm.selectFork(ethereumMainnetForkId);
        //ccipLocalSimulatorFork.switchChainAndRouteMessage(baseMainnetForkId);
        // vm.selectFork(ethereumMainnetForkId);
        // ccipLocalSimulatorFork.switchChainAndRouteMessage(roninMainnetForkId);
        // vm.selectFork(ethereumMainnetForkId);
        // ccipLocalSimulatorFork.switchChainAndRouteMessage(scrollMainnetForkId);
        // vm.selectFork(ethereumMainnetForkId);
        // ccipLocalSimulatorFork.switchChainAndRouteMessage(soneiumMainnetForkId);

        // Confirm final balance of each receiving address
        // vm.selectFork(baseMainnetForkId);
        // uint256 finalReceiver1Balance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS1);
        // assertEq(finalReceiver1Balance, LINK_TO_SEND1);

        // vm.selectFork(baseMainnetForkId);
        // uint256 finalReceiver2Balance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS2);
        // assertEq(finalReceiver2Balance, LINK_TO_SEND2);

        // vm.selectFork(baseMainnetForkId);
        // uint256 finalReceiver3Balance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS3);
        // assertEq(finalReceiver3Balance, LINK_TO_SEND3);

        vm.selectFork(baseMainnetForkId);
        uint256 finalReceiver1Balance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS1);
        assertEq(finalReceiver1Balance, LINK_TO_SEND1);
        uint256 finalReceiver2Balance = IERC20(baseMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS2);
        assertEq(finalReceiver2Balance, LINK_TO_SEND2);

        vm.selectFork(roninMainnetForkId);
        uint256 finalReceiver3Balance = IERC20(roninMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS3);
        assertEq(finalReceiver3Balance, LINK_TO_SEND3);
        uint256 finalReceiver4Balance = IERC20(roninMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS4);
        assertEq(finalReceiver4Balance, LINK_TO_SEND4);

        vm.selectFork(scrollMainnetForkId);
        uint256 finalReceiver5Balance = IERC20(scrollMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS1);
        assertEq(finalReceiver5Balance, LINK_TO_SEND1);
        uint256 finalReceiver6Balance = IERC20(scrollMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS2);
        assertEq(finalReceiver6Balance, LINK_TO_SEND2);

        vm.selectFork(soneiumMainnetForkId);
        uint256 finalReceiver7Balance = IERC20(soneiumMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS3);
        assertEq(finalReceiver7Balance, LINK_TO_SEND3);
        uint256 finalReceiver8Balance = IERC20(soneiumMainnetNetworkDetails.linkAddress).balanceOf(RECEIVING_ADDRESS4);
        assertEq(finalReceiver8Balance, LINK_TO_SEND4);
    }
}
