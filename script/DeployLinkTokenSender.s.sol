// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {LinkTokenSender} from "src/LinkTokenSender.sol";

contract DeployLinkTokenSender is Script {
    LinkTokenSender linkTokenSender;

    function run(address linkTokenAddress, address ccipRouterAddress) external returns (LinkTokenSender) {
        vm.startBroadcast();
        linkTokenSender = new LinkTokenSender(linkTokenAddress, ccipRouterAddress);
        vm.stopBroadcast();

        return (linkTokenSender);
    }
}
