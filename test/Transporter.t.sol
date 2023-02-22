// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/Transporter.sol";

contract TransportTest is Test {
    Transporter public transporter;

    function setUp() public {
        transporter = new Transporter(1);
    }

    function testDomainSet() public {
        assertEqUint(1, transporter.localDomain());
    } 

}