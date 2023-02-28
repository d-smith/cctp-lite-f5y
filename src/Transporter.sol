// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./BurnMessage.sol";
import "./Message.sol";
import "./IDelegatedMinter.sol";
import "openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

contract Transporter {
    uint32 public immutable localDomain;
    uint32 public immutable remoteDomain;
    uint32 public immutable messageBodyVersion;
    uint64 public nextAvailableNonce;
    address public immutable remoteAttestor;
    address private immutable minter;

    event MessageSent(bytes message);

    event DepositForBurn(
        uint64 indexed nonce,
        address indexed burnToken,
        uint256 amount,
        address indexed depositor,
        bytes32 mintRecipient,
        uint32 destinationDomain
    );

    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using Message for bytes29;
    using BurnMessage for bytes29;

    struct XmitRec {
        address sender;
        address recipient;
    }

    mapping(uint64 => XmitRec) private processedSends;

    error ZeroAmount();
    error ZeroAddressRecipient();
    error UnsupportedToken();
    error UnrecognizedAttestation();
    error UnsupportedBodyVersion();
    error UnsupportedSourceDomain();
    error UnsupportedDestinationDomain();
    error RequestPreviouslyProcessed();

    constructor(
        uint32 _localDomain, 
        uint32 _remoteDomain, 
        address _remoteAttestor,
        address _minter
    ) {
        localDomain = _localDomain;
        remoteDomain = _remoteDomain;
        remoteAttestor = _remoteAttestor;
        minter = _minter;
        messageBodyVersion = 1;
    }

    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64) {
        if(amount <= 0) revert ZeroAmount();
        if(mintRecipient == bytes32(0)) revert ZeroAddressRecipient();
        if(burnToken != minter) revert UnsupportedToken();

        // Burn the token
        ERC20Burnable(minter).burnFrom(msg.sender, amount);

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

    function receiveMessage( 
        bytes calldata message, 
        bytes calldata attestation
    ) external returns(bool) {
        validateAttestation(message, attestation);
        return true;
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

        return nonce;

    }
    
    function reserveAndIncrementNonce() internal returns (uint64) {
        uint64 nonceReserved = nextAvailableNonce;
        nextAvailableNonce = nextAvailableNonce + 1;
        return nonceReserved;
    }

    function validateAttestation(
        bytes calldata message,
        bytes calldata attestation
    ) internal  {
        bytes32 digest = keccak256(message);

        // For this simplified version we assume one signature
        address signerAddress = ECDSA.recover(digest, attestation);
        if(signerAddress != remoteAttestor) revert UnrecognizedAttestation();

        //TODO - full message verification
        bytes29 _msg = message.ref(0);
        if(Message._version(_msg) != messageBodyVersion) revert UnsupportedBodyVersion();
        if(Message._sourceDomain(_msg) != remoteDomain) revert UnsupportedSourceDomain();
        if(Message._destinationDomain(_msg) != localDomain) revert UnsupportedDestinationDomain();

        // Extract the nonce and see if we have processed this before
        uint64 sendNonce = Message._nonce(_msg);
        
        XmitRec memory xmit = processedSends[sendNonce];
        if(xmit.recipient != address(0)) revert RequestPreviouslyProcessed();

        // Extract sender and recipient, include those as the context assocaited
        // with the request nonce being processed.
        
        address sender = Message.bytes32ToAddress(
            Message._sender(_msg)
        );
        require(sender != address(0));

        address recipient = Message.bytes32ToAddress(
            Message._recipient(_msg)
        );
        require(recipient != address(0));

         XmitRec memory sendRec;
         sendRec.sender = sender;
         sendRec.recipient = recipient;

        processedSends[sendNonce] = sendRec;

        // Now do the mint

        bytes29 _burnMsg = Message._messageBody(_msg);
        uint256 amount = BurnMessage._getAmount(_burnMsg);
        if(amount <= 0) revert ZeroAmount();

        address burnMsgRecipient = Message.bytes32ToAddress(
            BurnMessage._getMintRecipient(_burnMsg)
        );
        
        require(burnMsgRecipient != address(0));
        require(burnMsgRecipient == recipient);

        IDelegatedMinter(minter).delegateMint(recipient, amount);

    }
}