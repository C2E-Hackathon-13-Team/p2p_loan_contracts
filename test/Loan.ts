
import { expect } from "chai";
import hre from "hardhat";
import * as fs from "fs";
import * as path from "path"




interface DeployedAddresses {
    [key: string]: string; 
}


describe("Loan", function () {

    let loan;
    let owner;
    let lancher;
    let investor;

    before(async function () {
        let chainId = hre.network.config.chainId
        let filePath = path.join(__dirname, '../ignition/deployments/chain-'+chainId+'/deployed_addresses.json')
        const data = fs.readFileSync( filePath , "utf8" );
        let deployedAddr = JSON.parse(data);
        loan = await hre.ethers.getContractAt('Loan',deployedAddr['LockModule#Loan']);
        [owner,lancher,investor] = await hre.ethers.getSigners();
        

    })

    it("查看账户余额", async function () {
        console.log('owner balance = ',await hre.ethers.provider.getBalance(owner.address));
        console.log('lancher balance = ',await hre.ethers.provider.getBalance(lancher.address));
        console.log('investor balance = ',await hre.ethers.provider.getBalance(investor.address));
    });


    it("新增项目", async function () {
        let current = Math.floor(Date.now() / 1000);
        current += 25 * 60 *60;
        const r = await loan.connect(lancher).createProject( 8000 , 0.6*1000000 , 12 , current , 1 )
        console.log(r)
    });

    it.only("出资", async function () {
        const r = await loan.connect(investor).contribute(1)
        console.log(r)
    });


    it("查看用户发起过的项目", async function () {
        const r = await loan.connect(lancher).getLaunchProjects(owner.address)
        console.log(r)
    });

    it('查看用户出资过的项目',async function(){
        const r = await loan.connect(investor).getContributeProjects(owner.address)
        console.log(r)
    })

    

})














