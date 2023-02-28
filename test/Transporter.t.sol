// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/Transporter.sol";
import "../src/Token.sol";
import {Message} from "../src/Message.sol";
import {Utils} from "./utils/Utils.sol";

contract TransportTest is Test {
    Transporter public transporter;
    Transporter public remoteTransporter;
    MyToken public myToken;
    MyToken public remoteToken;

    Utils internal utils;

    address payable[] internal users;
    address internal owner;
    address internal alice;
    address internal bob;

    uint32 immutable localDomain  = 1;
    uint32 immutable remoteDomain = 2;
    address immutable remoteAttestor = address(0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac);
    address immutable localSigner = address(0x73dA1eD554De26C467d97ADE090af6d52851745E);

    event MessageSent(bytes message);

    function setUpAddresses() internal {
        owner = address(this);
        vm.label(owner, "Owner");

        utils = new Utils();
        users = utils.createUsers(2);
    
        alice = users[0];
        vm.label(alice, "Alice");

        bob = users[1];
        vm.label(bob, "Bob");
    }

    function setUp() public {
        setUpAddresses();
        myToken = new MyToken();
        remoteToken = new MyToken();
        transporter = new Transporter(localDomain, remoteDomain, remoteAttestor, address(myToken));
        remoteTransporter = new Transporter(remoteDomain,localDomain, localSigner, address(remoteToken));
        remoteToken.addCCTPMinter(address(remoteTransporter));
    }

    function testDomainSet() public {
        assertEqUint(localDomain, transporter.localDomain());
    } 

    function testMyTokenOwner() public {
        assertEq(owner, myToken.owner());
    }

    function testTotalSupplyOnInstall() public {
        assertEq(myToken.totalSupply(), myToken.balanceOf(owner));
    }

    function formSentMessage(
        uint256 amount,
        address recipient,
        address sender,
        uint32 messageBodyVersion,
        uint32 sourceDomain,
        uint32 destinationDomain
    ) internal view returns (bytes memory) {
        
        bytes memory burnMessage = BurnMessage._formatMessage(
            messageBodyVersion,
            Message.addressToBytes32(address(myToken)),
            Message.addressToBytes32(recipient),
            amount,
            Message.addressToBytes32(address(sender))
        );

        bytes memory message = Message._formatMessage(
            messageBodyVersion,
            sourceDomain,
            destinationDomain,
            0, // Nonce value at test time
            Message.addressToBytes32(sender),
            Message.addressToBytes32(recipient),
            burnMessage
        );

        return message;
    } 

    function testBurnAmountNotZero() public {
        bytes32 b32addr = Message.addressToBytes32(bob);

        vm.prank(alice);
        vm.expectRevert(Transporter.ZeroAmount.selector);
        transporter.depositForBurn(
            0, remoteDomain, b32addr, address(myToken)
        );
    }

    function testRecipientAddressNotZero() public {
        

        vm.prank(alice);
        vm.expectRevert(Transporter.ZeroAddressRecipient.selector);
        transporter.depositForBurn(
            5, remoteDomain, bytes32(0), address(myToken)
        );
    }

    function testUnsupportedToken() public {
        bytes32 b32addr = Message.addressToBytes32(bob);

        vm.prank(alice);
        vm.expectRevert(Transporter.UnsupportedToken.selector);
        transporter.depositForBurn(
            5, remoteDomain, b32addr, address(0)
        );
    }


    function testBurnForDeposit() public {
        myToken.transfer(alice, 50);
        
        vm.prank(alice);
        myToken.approve(address(transporter), 10);
        
        vm.prank(owner);
        assertEq(10, myToken.allowance(alice, address(transporter)));
        assertEq(0, myToken.allowance(bob, address(transporter)));

        bytes32 b32addr = Message.addressToBytes32(bob);
        
        bytes memory message  = 
            formSentMessage(6,bob, alice, transporter.messageBodyVersion(),
                localDomain, remoteDomain);
        vm.expectEmit(true,true,true,true);
        emit MessageSent(message);

        uint256 startingSupply = myToken.totalSupply();
    
        vm.prank(alice);
        transporter.depositForBurn(
            6, remoteDomain, b32addr, address(myToken)
        );

        assertEq(44, myToken.balanceOf(address(alice)));
        assertEq(startingSupply - 6, myToken.totalSupply());
    }

    function testAttestorSigValidation() public {
        address foo = vm.addr(1);
        bytes memory message  = formSentMessage(6,bob, foo, 
            transporter.messageBodyVersion(), localDomain, remoteDomain);
        bytes32 digest = keccak256(message);
        

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        bytes memory enc = abi.encodePacked(r,s,v);

        vm.expectRevert(Transporter.UnrecognizedAttestation.selector);
        remoteTransporter.receiveMessage(message, enc);

    }

    function testMessageVersionCheck() public {
        bytes memory message  = formSentMessage(6,bob, alice, 666, localDomain, remoteDomain);
        bytes32 digest = keccak256(message);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xf9832eeac47db42efeb2eca01e6479bfde00fda8fdd0624d45efd0e4b9ddcd3b, digest);
        bytes memory enc = abi.encodePacked(r,s,v);

        vm.expectRevert(Transporter.UnsupportedBodyVersion.selector);
        remoteTransporter.receiveMessage(message, enc);

    }

    function testSourceDomainCheck() public {
        bytes memory message  = formSentMessage(6,bob, alice, 
            transporter.messageBodyVersion(), 12, remoteDomain);
        bytes32 digest = keccak256(message);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xf9832eeac47db42efeb2eca01e6479bfde00fda8fdd0624d45efd0e4b9ddcd3b, digest);
        bytes memory enc = abi.encodePacked(r,s,v);

        vm.expectRevert(Transporter.UnsupportedSourceDomain.selector);
        remoteTransporter.receiveMessage(message, enc);

    }

    function testDestinationDomainCheck() public {
        bytes memory message  = formSentMessage(6,bob, alice, 
            transporter.messageBodyVersion(), localDomain, 12);
        bytes32 digest = keccak256(message);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xf9832eeac47db42efeb2eca01e6479bfde00fda8fdd0624d45efd0e4b9ddcd3b, digest);
        bytes memory enc = abi.encodePacked(r,s,v);

        vm.expectRevert(Transporter.UnsupportedDestinationDomain.selector);
        remoteTransporter.receiveMessage(message, enc);

    }

    function testReceiveMessage() public {
        bytes memory message  = formSentMessage(6,bob, alice,
            transporter.messageBodyVersion(), localDomain, remoteDomain);
        bytes32 digest = keccak256(message);

        uint256 startSupply = remoteToken.totalSupply();

        // From ganache test environment signer address and private key
        // 0x73dA1eD554De26C467d97ADE090af6d52851745E
        // 0xf9832eeac47db42efeb2eca01e6479bfde00fda8fdd0624d45efd0e4b9ddcd3b
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xf9832eeac47db42efeb2eca01e6479bfde00fda8fdd0624d45efd0e4b9ddcd3b, digest);
        bytes memory enc = abi.encodePacked(r,s,v);

        uint256 remoteBalance = remoteToken.balanceOf(bob);
        assertEq(0, remoteBalance);
        
        bool received = remoteTransporter.receiveMessage(message, enc);
        assertTrue(received);

        remoteBalance = remoteToken.balanceOf(bob);
        assertEq(6, remoteBalance);
        assertEq(startSupply + 6, remoteToken.totalSupply());

        vm.expectRevert(Transporter.RequestPreviouslyProcessed.selector);
        remoteTransporter.receiveMessage(message, enc);

    }

}