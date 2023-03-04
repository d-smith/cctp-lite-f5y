
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
    const ethTransporterAddress = "0x938b27Abd4D9548fc0fD573371F489E39b5085Ea";
    const ethTokenAddress = "0xccFfF869b36A8a166194Bb36727De7A10E58278f";

    const ethTokenContract =  new web3.eth.Contract(myTokenAbi, ethTokenAddress, {from: ownerSigner.address});
    const transporterContract = new web3.eth.Contract(transporterAbi, ethTransporterAddress,{from: ownerSigner.address} );
    const messageContract = new web3.eth.Contract(messageAbi, ethTransporterAddress, {from: ownerSigner.address});

    // STEP 0: Fund caller
    console.log("fund the caller");
    const transferTxGas = await ethTokenContract.methods.transfer(ethSigner.address, 50).estimateGas();
    const transferTx = await ethTokenContract.methods.transfer(ethSigner.address, 50, ).send({gas:transferTxGas});
    const transferTxReceipt = await waitForTransaction(web3, transferTx.transactionHash);

    // STEP 1: Approve transporter contract to withdraw from our active eth address
    console.log("approve transporter burn amount");
    const approveTxGas = await ethTokenContract.methods.approve(ethTransporterAddress, 10).estimateGas()
    const approveTx = await ethTokenContract.methods.approve(ethTransporterAddress, 10).send({from: ethSigner.address, gas: approveTxGas})
    const approveTxReceipt = await waitForTransaction(web3, approveTx.transactionHash);

    const allowance = await ethTokenContract.methods.allowance(ethSigner.address, ethTransporterAddress).call();
    console.log(allowance);

    // STEP 2: Burn MyToken
    console.log("deposit for born");
    const burnTxGas = await transporterContract.methods.depositForBurn(6, REMOTE_DOMAIN, process.env.RECIPIENT_ADDRESS_BYTES32, ethTokenAddress).estimateGas();
    const burnTx = await transporterContract.methods.depositForBurn(6, REMOTE_DOMAIN, process.env.RECIPIENT_ADDRESS_BYTES32, ethTokenAddress).send({gas: burnTxGas});
    const burnTxReceipt = await waitForTransaction(web3, burnTx.transactionHash);

    // STEP 3: Grab the message from the event logs
    console.log("get message from log");
    const transactionReceipt = await web3.eth.getTransactionReceipt(burnTx.transactionHash);
    const eventTopic = web3.utils.keccak256('MessageSent(bytes)')
    const log = transactionReceipt.logs.find((l) => l.topics[0] === eventTopic)
    const messageBytes = web3.eth.abi.decodeParameters(['bytes'], log.data)[0]
    const messageHash = web3.utils.keccak256(messageBytes);

    console.log(`MessageBytes: ${messageBytes}`)
    console.log(`MessageHash: ${messageHash}`)
}

main();