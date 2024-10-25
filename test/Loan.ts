
import { expect } from "chai";
import hre from "hardhat";
import * as fs from "fs";
const path = require('path');



interface DeployedAddresses {
    [key: string]: string; 
}


describe("Loan", function () {

    let loan;

    before(async function () {
        let filePath = path.join(__dirname, '../ignition/deployments/chain-11155111/deployed_addresses.json')
        const data = fs.readFileSync( filePath , "utf8" );
        let deployedAddr = JSON.parse(data);
        loan = await hre.ethers.getContractAt('Loan',deployedAddr['LockModule#Loan']);
    })

    it("查看账户余额", async function () {
        const [signer] = await hre.ethers.getSigners();
        const balance = await hre.ethers.provider.getBalance(signer.address);
        console.log(balance);
    });


    it.only("新增项目", async function () {
        let r = await loan.createProject( 8000 , 0.6*1000000 , 12 , 1729953652 , 1 )
        console.log(r)
        
    });

    it("查看用户发起过的项目", async function () {
        const [signer] = await hre.ethers.getSigners();
        let r = await loan.getLaunchProjects(signer.address)
        console.log(r)
        
    });

    

})














