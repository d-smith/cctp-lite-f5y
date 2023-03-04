const  Web3 = require('web3');

const transporterAbi = require('../out/Transporter.sol/Transporter.abi.json');
const myTokenAbi = require('../out/Token.sol/MyToken.abi.json'); 

const REMOTE_DOMAIN=2;


const waitForTransaction = async(web3, txHash) => {
    let transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
    while(transactionReceipt != null && transactionReceipt.status === 'FALSE') {
        transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
        await new Promise(r => setTimeout(r, 4000));
    }
    return transactionReceipt;
}

const main = async () => {
    const web3 = new Web3(process.env.ETH_TESTNET_RPC);

    // Ganache account 1
    const ethSigner = web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY);
    web3.eth.accounts.wallet.add(ethSigner);

    const ownerSigner = web3.eth.accounts.privateKeyToAccount(process.env.DEPLOYER_KEY);
    web3.eth.accounts.wallet.add(ownerSigner);

    const mbSigner = web3.eth.accounts.privateKeyToAccount(process.env.MB_PRIVATE_KEY);
    web3.eth.accounts.wallet.add(mbSigner);

    const ethTokenAddress = "0xccFfF869b36A8a166194Bb36727De7A10E58278f";
    const ethTokenContract =  new web3.eth.Contract(myTokenAbi, ethTokenAddress, {from: ownerSigner.address});

    const ethTransporterAddress = "0x938b27Abd4D9548fc0fD573371F489E39b5085Ea";
    const transporterContract = new web3.eth.Contract(transporterAbi, ethTransporterAddress,{from: ethSigner.address} );

    const mbTransporterAddress = "0x42e2EE7Ba8975c473157634Ac2AF4098190fc741";
    const mbTransporterContract = new web3.eth.Contract(transporterAbi, ethTransporterAddress,{from: mbSigner.address} );

    const initialBalance = await ethTokenContract.methods.balanceOf(ethSigner.address).call();
    console.log(`initial balance of account 1 ${initialBalance}`);

    console.log("fund the caller");
    const transferTxGas = await ethTokenContract.methods.transfer(ethSigner.address, 50).estimateGas();
    const transferTx = await ethTokenContract.methods.transfer(ethSigner.address, 50, ).send({gas:transferTxGas});
    const transferTxReceipt = await waitForTransaction(web3, transferTx.transactionHash);
    //console.log(transferTxReceipt);

    const fundedBalance = await ethTokenContract.methods.balanceOf(ethSigner.address).call();
    console.log(`funded balance of account 1 ${fundedBalance}`);

    const initialAuth = await ethTokenContract.methods.allowance(ethSigner.address, ethTransporterAddress).call();
    console.log(`auth on start: ${initialAuth}`);

    console.log("approve transporter burn amount");
    const approveTxGas = await ethTokenContract.methods.approve(ethTransporterAddress, 11).estimateGas()
    const approveTx = await ethTokenContract.methods.approve(ethTransporterAddress, 11).send({from: ethSigner.address, gas: approveTxGas})
    const approveTxReceipt = await waitForTransaction(web3, approveTx.transactionHash);
    //console.log(approveTxReceipt)

    const updatedAuth = await ethTokenContract.methods.allowance(ethSigner.address, ethTransporterAddress).call();
    console.log(updatedAuth);

    console.log("deposit for burn");
    const burnTxGas = await transporterContract.methods.depositForBurn(6, REMOTE_DOMAIN, process.env.RECIPIENT_ADDRESS_BYTES32, ethTokenAddress).estimateGas();
    const burnTx = await transporterContract.methods.depositForBurn(6, REMOTE_DOMAIN, process.env.RECIPIENT_ADDRESS_BYTES32, ethTokenAddress).send({gas: burnTxGas});
    const burnTxReceipt = await waitForTransaction(web3, burnTx.transactionHash);
    //console.log(burnTxReceipt);

    console.log("get message from log");
    const transactionReceipt = await web3.eth.getTransactionReceipt(burnTx.transactionHash);
    const eventTopic = web3.utils.keccak256('MessageSent(bytes)')
    const log = transactionReceipt.logs.find((l) => l.topics[0] === eventTopic)
    const messageBytes = web3.eth.abi.decodeParameters(['bytes'], log.data)[0]
    const messageHash = web3.utils.keccak256(messageBytes);

    console.log(`MessageBytes: ${messageBytes}`)
    console.log(`MessageHash: ${messageHash}`)

    let attestationResponse = {};

    while(attestationResponse.attestation == undefined ||attestationResponse.attestation == '' ) {
        console.log(`${process.env.ENDPOINT}/${messageHash}`)
        const response = await fetch(`${process.env.ENDPOINT}/${messageHash}`);
        attestationResponse = await response.json()
        console.log(attestationResponse);
        await new Promise(r => setTimeout(r, 2000));
    }

    const attestationSignature = attestationResponse.attestation;
    console.log(`Signature: ${attestationSignature}`)

    web3.setProvider(process.env.MOONBEAM_LOCAL_RPC); // Connect web3 to AVAX testnet
    const receiveTxGas = await mbTransporterContract.methods.receiveMessage(messageBytes, attestationSignature).estimateGas();
    const receiveTx = await mbTransporterContract.methods.receiveMessage(messageBytes, attestationSignature).send({gas: receiveTxGas});
    const receiveTxReceipt = await waitForTransaction(web3, receiveTx.transactionHash);
    console.log('ReceiveTxReceipt: ', receiveTxReceipt)
}

main();