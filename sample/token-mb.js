const Web3 = require('web3');

const transporterAbi = require('../out/Transporter.sol/Transporter.abi.json');
const myTokenAbi = require('../out/Token.sol/MyToken.abi.json');

const mbContractDeployCtx = require(process.env.MB_DEPLOY_DETAILS);

const REMOTE_DOMAIN = 2;


const waitForTransaction = async (web3, txHash) => {
    let transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
    while (transactionReceipt != null && transactionReceipt.status === 'FALSE') {
        transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
        await new Promise(r => setTimeout(r, 4000));
    }
    return transactionReceipt;
}

const main = async () => {
    const web3 = new Web3(process.env.MOONBEAM_LOCAL_RPC);

    // Grab the mb contract addresses
    const mbTokenAddress = mbContractDeployCtx
        .transactions.filter(t => t.contractName == "MyToken")
        .map(t => t.contractAddress)[0];

    const mbTransporterAddress = mbContractDeployCtx
        .transactions.filter(t => t.contractName == "Transporter")
        .map(t => t.contractAddress)[0];

    console.log(myTokenAbi)


    console.log("load private key")
    const mbSigner = web3.eth.accounts.privateKeyToAccount(process.env.MB_PRIVATE_KEY);
    web3.eth.accounts.wallet.add(mbSigner);

    const recipientSigner = web3.eth.accounts.privateKeyToAccount(process.env.RECIPIENT_PRIVATE_KEY);
    web3.eth.accounts.wallet.add(recipientSigner);

    console.log("create token contract")
    const mbTokenContract = new web3.eth.Contract(myTokenAbi, mbTokenAddress, { from: mbSigner.address });
    console.log("create transporter contract")
    const mbTransporterContract = new web3.eth.Contract(transporterAbi, mbTransporterAddress, { from: mbSigner.address });

    console.log("get initial balance")
    const initialBalance = await mbTokenContract.methods.balanceOf(process.env.RECIPIENT_ADDRESS).call();
    console.log(`initial balance of account 1 ${initialBalance}`);

    console.log("fund the caller");
    const transferTxGas = await mbTokenContract.methods.transfer(process.env.RECIPIENT_ADDRESS, 50).estimateGas();
    const transferTx = await mbTokenContract.methods.transfer(process.env.RECIPIENT_ADDRESS, 50,).send({ gas: transferTxGas });
    const transferTxReceipt = await waitForTransaction(web3, transferTx.transactionHash);
    //console.log(transferTxReceipt);

    console.log("check funded balance");
    const fundedBalance = await mbTokenContract.methods.balanceOf(process.env.RECIPIENT_ADDRESS).call();
    console.log(`funded balance of account 1 ${fundedBalance}`);

    const initialAuth = await mbTokenContract.methods.allowance(process.env.RECIPIENT_ADDRESS, mbTransporterAddress).call();
    console.log(`auth on start: ${initialAuth}`);

    console.log("approve transporter burn amount");
    const approveTxGas = await mbTokenContract.methods.approve(mbTransporterAddress, 10).estimateGas()
    const approveTx = await mbTokenContract.methods.approve(mbTransporterAddress, 10).send({ from: process.env.RECIPIENT_ADDRESS, gas: approveTxGas })
    const approveTxReceipt = await waitForTransaction(web3, approveTx.transactionHash);
    //console.log(approveTxReceipt)

    console.log("check allowance")
    const updatedAuth = await mbTokenContract.methods.allowance(process.env.RECIPIENT_ADDRESS, mbTransporterAddress).call();
    console.log(updatedAuth);

    
}

main();