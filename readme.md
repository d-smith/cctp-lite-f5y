# cctp-list-f5y

Simplified version of CCTP as an illustration of the rough workings of the protocol. Built using foundry.

## Deploy

To local eth:

```
forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:8545
```

To local moonbeam

```
details soon...

```
## CLI Interactions

For exercising the CLI I ran a ganache node bootstrapped with a consistent test seed phrase to allow me to rely on specific address and key values captured in the 
.castenv environment file.

```
cast call $MYTOKENADDR "totalSupply()(uint256)"  --rpc-url  http://127.0.0.1:8545

# Transfer some tokens to account 1
cast send $MYTOKENADDR "transfer(address,uint256)" --private-key $DEPLOYER $ACCT1 50


cast call $MYTOKENADDR "balanceOf(address)" $ACCT1

cast send  $MYTOKENADDR "approve(address,uint256)" --private-key $ADDR1PK $TRANSPORTER 10

# How to derived bytes32 ref of account 1 address
cast call 0xdb98a5bfba239000213813b2615b8a96e950a79b "addressToBytes32(address)" $ACCT1

cast send $TRANSPORTER "depositForBurn(uint256,uint32,bytes32,address)" --private-key $ADDR1PK  6 2 $ACCT1BYTES32 $MYTOKENADDR
```

## Misc

Prefunded moonbeam dev accounts - see [here](https://docs.moonbeam.network/builders/get-started/networks/moonbeam-dev/#pre-funded-development-accounts)

We can use Gerald as the deployer, and Alith as the attestor