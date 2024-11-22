const web3 = require("./web3");

async function get(){
const accounts = await web3.eth.getAccounts();
const owner = accounts[0];
console.log(owner);
}
get();

