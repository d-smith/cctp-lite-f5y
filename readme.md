# cctp-list-f5y

Simplified version of CCTP as an illustration of the rough workings of the protocol. Built using foundry.

## Deploy

To local eth:

```
forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:8545
```

To local moonbeam

```
docker pull purestake/moonbeam:v0.29.0
docker run --rm --name moonbeam_development -p 9944:9944 -p 9933:9933 purestake/moonbeam:v0.29.0 --dev --ws-external --rpc-external

. .envlocalmb
forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:9933 --legacy

```
## CLI Interactions

For exercising the CLI I ran a ganache node bootstrapped with a consistent test seed phrase to allow me to rely on specific address and key values captured in the 
.castenv environment file.

Note that the contract addresses for MYTOKERADDR and TRANSPORTER are taken from run-latest.json the broadcast/deploy.sol directory. Update .castenv after running deploy.s.sol.

```
cast call $MYTOKENADDR "totalSupply()(uint256)"  --rpc-url  http://127.0.0.1:8545

# Transfer some tokens to account 1
cast send $MYTOKENADDR "transfer(address,uint256)" --private-key $DEPLOYER $ACCT1 50


cast call $MYTOKENADDR "balanceOf(address)" $ACCT1

cast send  $MYTOKENADDR "approve(address,uint256)" --private-key $ADDR1PK $TRANSPORTER 10

# How to derived bytes32 ref of account 1 address
cast call 0xdb98a5bfba239000213813b2615b8a96e950a79b "addressToBytes32(address)" $RECIPIENT

cast send $TRANSPORTER "depositForBurn(uint256,uint32,bytes32,address)" --private-key $ADDR1PK  6 2 $RECIPIENTBYTES32 $MYTOKENADDR
```

## Misc

Prefunded moonbeam dev accounts - see [here](https://docs.moonbeam.network/builders/get-started/networks/moonbeam-dev/#pre-funded-development-accounts)

We can use Gerald as the deployer, and Alith as the attestor

## End to End Scenario

### Set Up

Assume:

* Sender is Ganache account 1 (ACCT1)
* Recipient in moonbeam is account Faith - 0xC0F0f4ab324C46e55D02D0033343B4Be8A55532d
* Faith address in bytes32 is 

1. Local Ethereum running via Ganache, local moonbeam running as per above
2. Contracts deployed using envrionment set up as per .envlocaleth and .envlocalmb as shown above
    * Post deply update the mytoken and transporter contract addressed in .castenv, as well as
    the references in the attestor service (see below)
3. [Attestor service deployed](https://github.com/d-smith/attester), minimally an instance associated with attesting messages on the local etherem network
    * Deploy the CDK stack from the inf directory
    * Run the node script in the logscraper directory, connecting to the local ethereum node

### Allocate Tokens - Ethereum Domain

```
# Transfer some tokens to account 1
cast send $MYTOKENADDR "transfer(address,uint256)" --private-key $DEPLOYER $ACCT1 50

# Check account 1 balance
cast call $MYTOKENADDR "balanceOf(address)" $ACCT1

# Grant transporter contract an allowance for burning tokens from account 1
cast send  $MYTOKENADDR "approve(address,uint256)" --private-key $ADDR1PK $TRANSPORTER 10
```

### Deposit for Burn - Ethereum Domain

```
cast send $TRANSPORTER "depositForBurn(uint256,uint32,bytes32,address)" --private-key $ADDR1PK  6 2 $RECIPIENTBYTES32 $MYTOKENADDR
```

### Get attestation

Using the keccak256 hash of the message, get the attestation from the attestor endpoint:

```
curl  https://xxx.execute-api.us-east-1.amazonaws.com/prod/0x9a6a5410f3a3add7dd1b4e659f15c0cf678dc5d6cb82ce67b6d5063b5270fc8b
{"attestation":"0xb05955c9f977e6d574d81914d238ef68a89d7e6126aeff3729d8c7c26c515f5c5a68c02b08fa706673a2ac4d3eec108b7d1c896e7b9ab3aeac55e4f8c62792831c"}
```

### Receive the message and attestation on moonbeam

```
# Show initial balance
cast call $MYTOKENADDR "balanceOf(address)" $FAITH --rpc-url http://127.0.0.1:9933

# Receive message - NOTE: currently not working, looks like disconnect between transporting message and signature bytes and command line serialization
cast call $TRANSPORTER "receiveMessage(bytes,bytes)" --private-key $FAITHPK 0x00000001000000010000000200000000000000030000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000001000000000000000000000000c0a4b9e04fb55b1b498c634faeeb7c8dd5895b53000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000000000000000000000000000000000000000000000000000000000000060000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5 0xb05955c9f977e6d574d81914d238ef68a89d7e6126aeff3729d8c7c26c515f5c5a68c02b08fa706673a2ac4d3eec108b7d1c896e7b9ab3aeac55e4f8c62792831c --rpc-url http://127.0.0.1:9933
```