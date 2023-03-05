const ethDeploy = require(process.env.ETH_DEPLOY_DETAILS);

const main = async () => {
    console.log(ethDeploy.transactions);
    console.log(
        ethDeploy.transactions.filter(t => t.contractName == "MyToken")
            .map(t => t.contractAddress)
    )
}

main();