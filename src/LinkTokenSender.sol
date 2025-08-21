// SPDX-License-Identifier: MIT

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

pragma solidity ^0.8.30;

/*
██╗     ██╗███╗   ██╗██╗  ██╗    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
██║     ██║████╗  ██║██║ ██╔╝    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
██║     ██║██╔██╗ ██║█████╔╝        ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
██║     ██║██║╚██╗██║██╔═██╗        ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
███████╗██║██║ ╚████║██║  ██╗       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
                                                                             
███████╗███████╗███╗   ██╗██████╗ ███████╗██████╗                            
██╔════╝██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗                           
███████╗█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝                           
╚════██║██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗                           
███████║███████╗██║ ╚████║██████╔╝███████╗██║  ██║                           
╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝                           
*/

/**
 * @title LinkTokenSender
 * @author George Gorzhiyev
 * @notice under construction...
 */
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
        i_linkTokenAddress = linkTokenAddress; // do i need this?
        i_ccipRouter = IRouterClient(ccipRouterAddress);
    }

    /*---------> External Functions <---------------------------*/
    /*//////////////////////////////////////////////////////////*/
    /* (Work in progress) */
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
    /**
     * @param receivingAddress The address to receive the LINK tokens
     * @param amountToSend The amount of LINK tokens to send
     * @param destinationChain The destination chain ID
     * @dev Basic cross-chain LINK transfer function for testing
     */
    function sendLinkCrossChain(address receivingAddress, uint256 amountToSend, uint64 destinationChain) external {
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(receivingAddress, i_linkTokenAddress, amountToSend, i_linkTokenAddress);

        // Get the fee for sending the message
        uint256 fees = i_ccipRouter.getFee(destinationChain, evm2AnyMessage);

        // Transfer LINK tokens to the contract for sending + fee
        i_linkToken.transferFrom(msg.sender, address(this), amountToSend + fees);

        // Approve CCIP Router to spend LINK tokens
        i_linkToken.approve(address(i_ccipRouter), (amountToSend + fees));

        // Send the message through CCIP
        i_ccipRouter.ccipSend(destinationChain, evm2AnyMessage);
    }

    function _buildCCIPMessage(address _receiver, address _tokenToSend, uint256 _amountToSend, address _feeTokenAddress)
        private
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        // Create the EVMTokenAmount array with the token and amount to send
        Client.EVMTokenAmount[] memory tokenAmount = new Client.EVMTokenAmount[](1);
        tokenAmount[0] = Client.EVMTokenAmount({token: _tokenToSend, amount: _amountToSend});

        // Create the EVM2AnyMessage struct and return it
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: "",
            tokenAmounts: tokenAmount,
            feeToken: _feeTokenAddress,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV2({
                    gasLimit: 0, // Default gas limit, can be adjusted
                    allowOutOfOrderExecution: true // Default value, can be changed as needed
                })
            )
        });
    }

    // <---// WORK IN PROGRESS - TESTING //------------------------------------->
    // <------------------------------------------------------------------------>
}
