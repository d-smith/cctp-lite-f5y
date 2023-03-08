// Test data

//MessageBytes: 0x000000010000000100000002000000000000000f0000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000001000000000000000000000000c0a4b9e04fb55b1b498c634faeeb7c8dd5895b53000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000000000000000000000000000000000000000000000000000000000000060000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5
//MessageHash: 0x63dc581bac039578ae1b4d8855b967145b777f127ff749581d83ca7d69211db8
//Signature: 0xd95022702bcefa852f69f1c4f3191c1acd6d7e54137d4fe1e7e03e8a3674d2d73ff29886a0bc6f2dc9b01936c739c3f3ac32a92e97ead7800155f66d68ca4ca91b
// got back 0x569c9e81e31016e24b62126ece0338afbb2d5a6d
const Web3 = require('web3');

const transporterAbi = require('../out/Transporter.sol/Transporter.abi.json');

const mbContractDeployCtx = require(process.env.MB_DEPLOY_DETAILS);



const waitForTransaction = async (web3, txHash) => {
    let transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
    while (transactionReceipt != null && transactionReceipt.status === 'FALSE') {
        transactionReceipt = await web3.eth.getTransactionReceipt(txHash);
        await new Promise(r => setTimeout(r, 4000));
    }
    return transactionReceipt;
}

let main = async () => {
    const web3 = new Web3(process.env.MOONBEAM_LOCAL_RPC);

        //const messageBytes = web3.eth.abi.encodeParameter('bytes', '0x000000010000000100000002000000000000000f0000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000001000000000000000000000000c0a4b9e04fb55b1b498c634faeeb7c8dd5895b53000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000000000000000000000000000000000000000000000000000000000000060000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5');
        const messageBytes ='0x000000010000000100000002000000000000000f0000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000001000000000000000000000000c0a4b9e04fb55b1b498c634faeeb7c8dd5895b53000000000000000000000000c0f0f4ab324c46e55d02d0033343b4be8a55532d00000000000000000000000000000000000000000000000000000000000000060000000000000000000000009949f7e672a568bb3ebeb777d5e8d1c1107e96e5';
    const digest = web3.utils.keccak256(messageBytes);
    console.log(digest);

    const signed = web3.eth.accounts.sign(digest, '0xf9832eeac47db42efeb2eca01e6479bfde00fda8fdd0624d45efd0e4b9ddcd3b');
    console.log(signed);

    const walletSigner = web3.eth.accounts.privateKeyToAccount('0xf9832eeac47db42efeb2eca01e6479bfde00fda8fdd0624d45efd0e4b9ddcd3b');
    web3.eth.accounts.wallet.add(walletSigner);

    console.log(web3.eth.accounts.recover(digest, signed.signature))

    walletSigned = walletSigner.sign(digest)
    console.log(walletSigned)
    


    const mbTransporterAddress = mbContractDeployCtx
        .transactions.filter(t => t.contractName == "Transporter")
        .map(t => t.contractAddress)[0];

    const mbSigner = web3.eth.accounts.privateKeyToAccount(process.env.MB_PRIVATE_KEY);
    web3.eth.accounts.wallet.add(mbSigner);

    const mbTransporterContract = new web3.eth.Contract(transporterAbi, mbTransporterAddress, { from: mbSigner.address });

    //const receiveTxGas = await mbTransporterContract.methods.receiveMessage(messageBytes, signed.signature).estimateGas();
    //const receiveTx = await mbTransporterContract.methods.receiveMessage(messageBytes, signed.signature).send({ gas: receiveTxGas });
    //const receiveTxReceipt = await waitForTransaction(web3, receiveTx.transactionHash);
    //console.log('ReceiveTxReceipt: ', receiveTxReceipt);

    console.log(walletSigner)
    const s = await web3.eth.sign(digest,walletSigner.address);
    console.log(`s is ${s}`)

    const receiveTxGas = await mbTransporterContract.methods.recover(messageBytes, signed.signature).estimateGas();
    const receiveTx = await mbTransporterContract.methods.recover(messageBytes, signed.signature).send({ gas: receiveTxGas });
    const receiveTxReceipt = await waitForTransaction(web3, receiveTx.transactionHash);
    console.log('ReceiveTxReceipt: ', receiveTxReceipt);

    const recovered = await mbTransporterContract.methods.recover(messageBytes, s).call();
    
    
    console.log(recovered);
}

main();