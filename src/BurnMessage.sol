// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./TypedMemView.sol";

// Using the burn message from CCTP from circlefin

library BurnMessage {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    uint8 private constant VERSION_INDEX = 0;
    uint8 private constant VERSION_LEN = 4;
    uint8 private constant BURN_TOKEN_INDEX = 4;
    uint8 private constant BURN_TOKEN_LEN = 32;
    uint8 private constant MINT_RECIPIENT_INDEX = 36;
    uint8 private constant MINT_RECIPIENT_LEN = 32;
    uint8 private constant AMOUNT_INDEX = 68;
    uint8 private constant AMOUNT_LEN = 32;
    uint8 private constant MSG_SENDER_INDEX = 100;
    uint8 private constant MSG_SENDER_LEN = 32;
    // 4 byte version + 32 bytes burnToken + 32 bytes mintRecipient + 32 bytes amount + 32 bytes messageSender
    uint8 private constant BURN_MESSAGE_LEN = 132;

    /**
     * @notice Formats Burn message
     * @param _version The message body version
     * @param _burnToken The burn token address on source domain as bytes32
     * @param _mintRecipient The mint recipient address as bytes32
     * @param _amount The burn amount
     * @param _messageSender The message sender
     * @return Burn formatted message.
     */
    function _formatMessage(
        uint32 _version,
        bytes32 _burnToken,
        bytes32 _mintRecipient,
        uint256 _amount,
        bytes32 _messageSender
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _version,
                _burnToken,
                _mintRecipient,
                _amount,
                _messageSender
            );
    }

    /**
     * @notice Retrieves the burnToken from a DepositForBurn BurnMessage
     * @param _message The message
     * @return sourceToken address as bytes32
     */
    function _getMessageSender(bytes29 _message)
        internal
        pure
        returns (bytes32)
    {
        return _message.index(MSG_SENDER_INDEX, MSG_SENDER_LEN);
    }

    /**
     * @notice Retrieves the burnToken from a DepositForBurn BurnMessage
     * @param _message The message
     * @return sourceToken address as bytes32
     */
    function _getBurnToken(bytes29 _message) internal pure returns (bytes32) {
        return _message.index(BURN_TOKEN_INDEX, BURN_TOKEN_LEN);
    }

    /**
     * @notice Retrieves the mintRecipient from a BurnMessage
     * @param _message The message
     * @return mintRecipient
     */
    function _getMintRecipient(bytes29 _message)
        internal
        pure
        returns (bytes32)
    {
        return _message.index(MINT_RECIPIENT_INDEX, MINT_RECIPIENT_LEN);
    }

    /**
     * @notice Retrieves the amount from a BurnMessage
     * @param _message The message
     * @return amount
     */
    function _getAmount(bytes29 _message) internal pure returns (uint256) {
        return _message.indexUint(AMOUNT_INDEX, AMOUNT_LEN);
    }

    /**
     * @notice Retrieves the version from a Burn message
     * @param _message The message
     * @return version
     */
    function _getVersion(bytes29 _message) internal pure returns (uint32) {
        return uint32(_message.indexUint(VERSION_INDEX, VERSION_LEN));
    }

    /**
     * @notice Reverts if burn message is malformed or invalid length
     * @param _message The burn message as bytes29
     */
    function _validateBurnMessageFormat(bytes29 _message) internal pure {
        require(_message.isValid(), "Malformed message");
        require(_message.len() == BURN_MESSAGE_LEN, "Invalid message length");
    }
}