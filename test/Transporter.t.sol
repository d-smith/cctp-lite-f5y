// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/Transporter.sol";
import "../src/Token.sol";
import {Message} from "../src/Message.sol";
import {Utils} from "./utils/Utils.sol";

contract TransportTest is Test {
    Transporter public transporter;
    MyToken public myToken;

    Utils internal utils;

    address payable[] internal users;
    address internal owner;
    address internal alice;
    address internal bob;

    uint32 immutable localDomain  = 1;
    uint32 immutable remoteDomain = 2;

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
        transporter = new Transporter(localDomain);
        myToken = new MyToken();
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
        address sender
    ) internal view returns (bytes memory) {
        
        bytes memory burnMessage = BurnMessage._formatMessage(
            transporter.messageBodyVersion(),
            Message.addressToBytes32(address(myToken)),
            Message.addressToBytes32(recipient),
            amount,
            Message.addressToBytes32(address(sender))
        );

        bytes memory message = Message._formatMessage(
            transporter.messageBodyVersion(),
            localDomain,
            remoteDomain,
            0, // Nonce value at test time
            Message.addressToBytes32(sender),
            Message.addressToBytes32(recipient),
            burnMessage
        );

        return message;
    } 

    function testBurnForDeposit() public {
        myToken.transfer(alice, 50);
        
        vm.prank(alice);
        myToken.approve(address(transporter), 10);
        
        vm.prank(owner);
        assertEq(10, myToken.allowance(alice, address(transporter)));
        assertEq(0, myToken.allowance(bob, address(transporter)));

        bytes32 b32addr = Message.addressToBytes32(bob);
        
        bytes memory message  = formSentMessage(6,bob, alice);
        vm.expectEmit(true,true,true,true);
        emit MessageSent(message);


    
        vm.prank(alice);
        transporter.depositForBurn(
            6, remoteDomain, b32addr, address(myToken)
        );

        assertEq(44, myToken.balanceOf(address(alice)));
    }

}