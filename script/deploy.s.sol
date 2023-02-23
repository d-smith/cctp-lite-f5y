// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Transporter.sol";
import "../src/Token.sol";

contract DeployScript is Script {
    uint256 private deployerPrivateKey;
    uint32 private localDomain;
    address private transporterAddress;
    address private myTokenAddress;


    function setUp() public {
        deployerPrivateKey = vm.envUint(
            "DEPLOYER_KEY"
        );

        localDomain = uint32(
            vm.envUint("LOCAL_DOMAIN")
        );
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        Transporter transporter = new Transporter(localDomain);
        transporterAddress = address(transporter);

        MyToken myToken = new MyToken();
        myTokenAddress = address(myToken);
        vm.stopBroadcast();
    }

}