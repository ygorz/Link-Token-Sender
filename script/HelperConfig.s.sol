// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {Register} from "lib/chainlink-local/src/ccip/Register.sol";

/*
Not currently used, need to figure out how to use this more gracefully
*/

contract HelperConfig is Script {
    mapping(uint256 chainId => Register.NetworkDetails) internal s_networkDetails;

    constructor() {
        // Ethereum Mainnet CCIP Network Details
        s_networkDetails[1] = Register.NetworkDetails({
            chainSelector: 5009297550715157269,
            routerAddress: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
            linkAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            wrappedNativeAddress: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            ccipBnMAddress: address(0),
            ccipLnMAddress: address(0),
            rmnProxyAddress: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
            registryModuleOwnerCustomAddress: 0x4855174E9479E211337832E109E7721d43A4CA64,
            tokenAdminRegistryAddress: 0xb22764f98dD05c789929716D677382Df22C05Cb6
        });

        // Arbitrum CCIP Network Details
        s_networkDetails[42161] = Register.NetworkDetails({
            chainSelector: 4949039107694359620,
            routerAddress: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
            linkAddress: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
            wrappedNativeAddress: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            ccipBnMAddress: address(0),
            ccipLnMAddress: address(0),
            rmnProxyAddress: 0xC311a21e6fEf769344EB1515588B9d535662a145,
            registryModuleOwnerCustomAddress: 0x1f1df9f7fc939E71819F766978d8F900B816761b,
            tokenAdminRegistryAddress: 0x39AE1032cF4B334a1Ed41cdD0833bdD7c7E7751E
        });

        // Base CCIP Network Details
        s_networkDetails[8453] = Register.NetworkDetails({
            chainSelector: 15971525489660198786,
            routerAddress: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
            linkAddress: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
            wrappedNativeAddress: 0x4200000000000000000000000000000000000006,
            ccipBnMAddress: address(0),
            ccipLnMAddress: address(0),
            rmnProxyAddress: 0xC842c69d54F83170C42C4d556B4F6B2ca53Dd3E8,
            registryModuleOwnerCustomAddress: 0xAFEd606Bd2CAb6983fC6F10167c98aaC2173D77f,
            tokenAdminRegistryAddress: 0x6f6C373d09C07425BaAE72317863d7F6bb731e37
        });
    }

    function getNetworkDetails(uint256 chainId) external view returns (Register.NetworkDetails memory networkDetails) {
        networkDetails = s_networkDetails[chainId];
    }

    function setNetworkDetails(uint256 chainId, Register.NetworkDetails memory networkDetails) external {
        s_networkDetails[chainId] = networkDetails;
    }
}
