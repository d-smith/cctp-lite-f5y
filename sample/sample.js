
const  Web3 = require('web3');

const myTokenAbi = require('../out/Token.sol/MyToken.abi.json'); // forge compile --extra-output-files abi
const messageAbi = require('../out/Message.sol/Message.abi.json');
const transporterAbi = require('../out/Transporter.sol/Transporter.abi.json');

const waitForTransaction = async(web3, txHash) => {
    let transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
    while(transactionReceipt != null && transactionReceipt.status === 'FALSE') {
        transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
        await new Promise(r => setTimeout(r, 4000));
    }
    return transactionReceipt;
}

const REMOTE_DOMAIN=2;

const main = async() => {

    const web3 = new Web3(process.env.ETH_TESTNET_RPC);

    // Add ETH private key used for signing transactions
    const ethSigner = web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY);
    web3.eth.accounts.wallet.add(ethSigner);

    // Add CONTRACT_OWNER private key
    const ownerSigner = web3.eth.accounts.privateKeyToAccount(process.env.DEPLOYER_KEY);
    web3.eth.accounts.wallet.add(ownerSigner);

    // Add Moonbeam private key used for signing transactions
    //const moonbeamSigner = web3.eth.accounts.privateKeyToAccount(process.env.MOONBEAM_PRIVATE_KEY);
    //web3.eth.accounts.wallet.add(moonbeamSigner);

    // Contract addresses
    const ethTransporterAddress = "0xa7F08a6F40a00f4ba0eE5700F730421C5810f848";
    const ethTokenAddress = "0xC0a4b9e04fB55B1b498c634FAEeb7C8dD5895b53";

    const ethTokenContract =  new web3.eth.Contract(myTokenAbi, ethTokenAddress, {from: ownerSigner.address});
    const transporterContract = new web3.eth.Contract(transporterAbi, ethTransporterAddress,{from: ownerSigner.address} );
    const messageContract = new web3.eth.Contract(messageAbi, ethTransporterAddress, {from: ownerSigner.address});

    // STEP 0: Fund caller
    const transferTxGas = await ethTokenContract.methods.transfer(ethSigner.address, 50).estimateGas();
    const transferTx = await ethTokenContract.methods.transfer(ethSigner.address, 50, ).send({gas:transferTxGas});
    const transferTxReceipt = await waitForTransaction(web3, transferTx.transactionHash);
    console.log('transferTxReceipt: ', transferTxReceipt)

    // STEP 1: Approve transporter contract to withdraw from our active eth address
    const approveTxGas = await ethTokenContract.methods.approve(ethTransporterAddress, 6).estimateGas()
    const approveTx = await ethTokenContract.methods.approve(ethTransporterAddress, 6).send({from: ethSigner.address, gas: approveTxGas})
    const approveTxReceipt = await waitForTransaction(web3, approveTx.transactionHash);
    console.log('ApproveTxReceipt: ', approveTxReceipt)

    // STEP 2: Burn MyToken
    

    const burnTxGas = await transporterContract.methods.depositForBurn(6, REMOTE_DOMAIN, process.env.RECIPIENT_ADDRESS_BYTES32, ethTokenAddress).estimateGas();
    const burnTx = await transporterContract.methods.depositForBurn(6, REMOTE_DOMAIN, process.env.RECIPIENT_ADDRESS_BYTES32, ethTokenAddress).send({gas: burnTxGas});
    const burnTxReceipt = await waitForTransaction(web3, burnTx.transactionHash);
    console.log('BurnTxReceipt: ', burnTxReceipt)
}

main();