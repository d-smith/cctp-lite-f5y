# cctp-list-f5y

Simplified version of CCTP as an illustration of the rough workings of the protocol. Built using foundry.

## Deploy

To run a local ethereum node wit the preseeded accounts used for the sample, first do a [global install of ganache](https://www.npmjs.com/package/ganache), then in a dedicated shell:

```
cd ganache
npm run ganache
```

Then, to install to local eth:

```
. .envlocalevm
forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:8545 --extra-output-files abi
```

To local moonbeam

```
docker pull purestake/moonbeam:v0.29.0
docker run --rm --name moonbeam_development -p 9944:9944 -p 9933:9933 purestake/moonbeam:v0.29.0 --dev --ws-external --rpc-external 

. .envlocalmb
forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:9933 --legacy --extra-output-files abi
```

## End to End Scenario

This section describes how to set up a test scenario to burn tokens on ethereum and mint tokens on
moonbeam.

### Set Up

0. Generate the abi files by issuing a `forge clean` then a `forge compile --extra-output-files abi` in the 
top level directory of this project.
1. Deploy to both Ethereum and Moonbeam local dev environments as described above. Note that the contract abis
must be generated as part of the deploy as the demo script reads contract addresses from run-latest.json 
under the broadcast/deploy.s.output output for each chain.
2. Deploy the attestor infrastructure stack from [this project](https://github.com/d-smith/attester), noting the dependencies:
    * contract address
    * signing key from account 10 (ethereum)
3. Note the attestorApi endpoint from the attestor stack output, set an ENDPOINT env variable equal to that, e.g. 
`export ENDPOINT=https://6xac0825ak.execute-api.us-east-1.amazonaws.com/prod`
4. In the samples directory, set the samples enviroment: `. .env`
5. Run the sample to see tokens burned on ethereum and minted on moonbeam - `node token-sample.js`

## CLI Interaction

For exercising the CLI I ran a ganache node bootstrapped with a consistent test seed phrase to allow me to rely on specific address and key values captured in the 
.castenv environment file.

Note that the contract addresses for MYTOKERADDR and TRANSPORTER are taken from run-latest.json the broadcast/deploy.sol directory. Update .castenv after running deploy.s.sol.

```
cast call $MYTOKENADDR "totalSupply()(uint256)"  --rpc-url  http://127.0.0.1:8545

# Transfer some tokens to account 1
cast send $MYTOKENADDR "transfer(address,uint256)" --private-key $DEPLOYER $ACCT1 50


cast call $MYTOKENADDR "balanceOf(address)" $ACCT1

cast send  $MYTOKENADDR "approve(address,uint256)" --private-key $ADDR1PK $TRANSPORTER 10

# How to derive bytes32 ref of account 1 address
cast call 0xdb98a5bfba239000213813b2615b8a96e950a79b "addressToBytes32(address)" $RECIPIENT

cast send $TRANSPORTER "depositForBurn(uint256,uint32,bytes32,address)" --private-key $ADDR1PK  6 2 $RECIPIENTBYTES32 $MYTOKENADDR
```

## Misc

Prefunded moonbeam dev accounts - see [here](https://docs.moonbeam.network/builders/get-started/networks/moonbeam-dev/#pre-funded-development-accounts)


## Transport between ETH and OP via CCTP

Just for grins, should see about native bridging too.

* Use .envL1 and .envL2
* Assume the same signer


```
. .envL1
forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:8545 --extra-output-files abi --legacy --slow

. .envL2
forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:9545 --extra-output-files abi --legacy --slow
```


