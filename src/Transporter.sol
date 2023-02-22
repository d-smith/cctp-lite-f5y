// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./messages/BurnMessage.sol";
import "./messages/Message.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Transporter {
    uint32 public immutable localDomain;
    uint32 public immutable messageBodyVersion;
    uint64 public nextAvailableNonce;

    constructor(uint32 _localDomain) {
        localDomain = _localDomain;
        messageBodyVersion = 1;
    }

    event MessageSent(bytes message);

    event DepositForBurn(
        uint64 indexed nonce,
        address indexed burnToken,
        uint256 amount,
        address indexed depositor,
        bytes32 mintRecipient,
        uint32 destinationDomain
    );

    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64) {
        require(amount > 0);
        require(mintRecipient != bytes32(0));
        require(burnToken != address(0));

        // Burn the token
        ERC20Burnable burnableToken = ERC20Burnable(burnToken);
        burnableToken.burnFrom(msg.sender, amount);

        // Form the message
        bytes memory burnMessage = BurnMessage._formatMessage(
            messageBodyVersion,
            Message.addressToBytes32(burnToken),
            mintRecipient,
            amount,
            Message.addressToBytes32(msg.sender)
        );

        // Generate the burn event which returns the nonce
        uint64 nonce = sendDepositForBurnMessage(
            destinationDomain,
            mintRecipient,
            burnMessage
        );

        // Emit the BurnForDeposit event
        emit DepositForBurn(
            nonce,
            burnToken,
            amount,
            msg.sender,
            mintRecipient,
            destinationDomain
        );

        return nonce;

    }

    function sendDepositForBurnMessage(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes memory burnMessage
    ) internal returns (uint64) {
        uint64 nonce = reserveAndIncrementNonce();
        bytes32 messageSender = Message.addressToBytes32(msg.sender);

        bytes memory message = Message._formatMessage(
            messageBodyVersion,
            localDomain,
            destinationDomain,
            nonce,
            messageSender,
            recipient,
            burnMessage
        );

        emit MessageSent(message);

    }
    
    function reserveAndIncrementNonce() internal returns (uint64) {
        uint64 nonceReserved = nextAvailableNonce;
        nextAvailableNonce = nextAvailableNonce + 1;
        return nonceReserved;
    }
}