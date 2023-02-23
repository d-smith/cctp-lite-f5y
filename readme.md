# cctp-list-f5y

Simplified version of CCTP as an illustration of the rough workings of the protocol. Built using foundry.

## Deploy

forge script script/deploy.s.sol:DeployScript --broadcast --rpc-url http://127.0.0.1:8545

## CLI Interactions

cast call "0xa7F08a6F40a00f4ba0eE5700F730421C5810f848" "totalSupply()(uint256)"  --rpc-url  http://127.0.0.1:8545
