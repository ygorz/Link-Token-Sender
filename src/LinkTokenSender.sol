// SPDX-License-Identifier: MIT

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

pragma solidity ^0.8.30;

contract LinkTokenSender {
    /*---------> ERRORS <---------------------------------------*/
    /*//////////////////////////////////////////////////////////*/
    error LinkTokenSender__ReceivingAddressAndAmountMismatch();
    error LinkTokenSender__NotEnoughLinkToSend();
    error LinkTokenSender__LinkApprovalFailed();

    /*---------> STATE VARIABLES <------------------------------*/
    /*//////////////////////////////////////////////////////////*/
    LinkTokenInterface private immutable i_linkToken;
    IRouterClient private immutable i_ccipRouter;
    address private immutable i_linkTokenAddress;

    /*---------> FUNCTIONS <------------------------------------*/
    /*//////////////////////////////////////////////////////////*/
    constructor(address linkTokenAddress, address ccipRouterAddress) {
        i_linkToken = LinkTokenInterface(linkTokenAddress);
        i_linkTokenAddress = linkTokenAddress;
        i_ccipRouter = IRouterClient(ccipRouterAddress);
    }

    /*---------> External Functions <---------------------------*/
    /*//////////////////////////////////////////////////////////*/
    function sendLink(address[] calldata receivingAddresses, uint256[] calldata amountsToSend) external {
        // Check if the length of receivingAddresses and amountsToSend match
        if (receivingAddresses.length != amountsToSend.length) {
            revert LinkTokenSender__ReceivingAddressAndAmountMismatch();
        }

        // Calculate the total amount of LINK to send
        uint256 totalAmountToSend;
        for (uint256 i = 0; i < amountsToSend.length; i++) {
            totalAmountToSend += amountsToSend[i];
        }

        // Check if the sender has enough LINK tokens
        uint256 senderBalance = i_linkToken.balanceOf(msg.sender);
        if (senderBalance < totalAmountToSend) {
            revert LinkTokenSender__NotEnoughLinkToSend();
        }

        // Approve LinkTokenSender to spend the total amount of LINK tokens
        (bool success) = i_linkToken.approve(address(this), totalAmountToSend);
        if (!success) {
            revert LinkTokenSender__LinkApprovalFailed();
        }

        // Transfer LINK tokens to each receiving address
        uint256 amountOfTxs = receivingAddresses.length;
        for (uint256 i = 0; i < amountOfTxs; i++) {
            i_linkToken.transferFrom(msg.sender, receivingAddresses[i], amountsToSend[i]);
        }
    }

    // <------------------------------------------------------------------------>
    // <---// WORK IN PROGRESS - TESTING //------------------------------------->
    function sendLinkCrossChain(address receivingAddress, uint256 amountToSend) external {
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(receivingAddress, i_linkTokenAddress, amountToSend, i_linkTokenAddress);
    }

    function _buildCCIPMessage(address _receiver, address _tokenToSend, uint256 _amountToSend, address _feeTokenAddress)
        private
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        return Client.EVM2AnyMessage{
            receiver: abi.encode(_receiver),
            data: abi.encode(_tokenToSend, _amountToSend),
            tokenAmounts: new EVMTokenAmount[](0),
            feeToken: _feeTokenAddress,
            extraArgs: ""
        };

        /*
        struct EVM2AnyMessage {
            bytes receiver; // abi.encode(receiver address) for dest EVM chains
            bytes data; // Data payload
            EVMTokenAmount[] tokenAmounts; // Token transfers
            address feeToken; // Address of feeToken. address(0) means you will send msg.value.
            bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV2)
        }
        */
    }

    // <---// WORK IN PROGRESS - TESTING //------------------------------------->
    // <------------------------------------------------------------------------>
}
