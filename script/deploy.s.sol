// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Transporter.sol";
import "../src/Token.sol";


contract DeployScript is Script {
    uint256 private deployerPrivateKey;
    uint32 private localDomain;
    uint32 private remoteDomain;
    address private transporterAddress;
    address private myTokenAddress;
    address private remoteAttestor;


    function setUp() public {
        deployerPrivateKey = vm.envUint(
            "DEPLOYER_KEY"
        );

        localDomain = uint32(
            vm.envUint("LOCAL_DOMAIN")
        );

        remoteDomain = uint32(
            vm.envUint("REMOTE_DOMAIN")
        );

        remoteAttestor = vm.envAddress("REMOTE_ATTESTOR_ADDRESS");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        MyToken myToken = new MyToken();
        myTokenAddress = address(myToken);
        

        Transporter transporter = new Transporter(localDomain, remoteDomain, remoteAttestor, myTokenAddress);
        transporterAddress = address(transporter);
        myToken.addCCTPMinter(address(transporterAddress));

        vm.stopBroadcast();
    }

}