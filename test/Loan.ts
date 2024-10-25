
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
    let investor1;
    let investor2;

    before(async function () {
        let chainId = hre.network.config.chainId
        let filePath = path.join(__dirname, '../ignition/deployments/chain-'+chainId+'/deployed_addresses.json')
        const data = fs.readFileSync( filePath , "utf8" );
        let deployedAddr = JSON.parse(data);
        loan = await hre.ethers.getContractAt('Loan',deployedAddr['LockModule#Loan']);
        [owner,lancher,investor1,investor2] = await hre.ethers.getSigners();
        

    })

    it("查看账户余额", async function () {
        console.log('owner balance = ',await hre.ethers.provider.getBalance(owner.address));
        console.log('lancher balance = ',await hre.ethers.provider.getBalance(lancher.address));
        console.log('investor1 balance = ',await hre.ethers.provider.getBalance(investor1.address));
        console.log('investor2 balance = ',await hre.ethers.provider.getBalance(investor2.address));
    });


    it("新增项目", async function () {
        let current = Math.floor(Date.now() / 1000);
        current += 25 * 60 *60;
        const r = await loan.connect(lancher).createProject( 8000 , 0.6*1000000 , 12 , current , 1 )
        console.log(r)
    });

    it.only("出资", async function () {
        const r1 = await loan.connect(investor1).contribute(0,{ value: 3000 })
        console.log(r1)
        const r2 = await loan.connect(investor2).contribute(0,{ value: 5000 })
        console.log(r2)
    });


    it("查看用户发起过的项目", async function () {
        console.log(lancher.address)
        const r = await loan.connect(lancher).getLaunchProjects(lancher.address)
        console.log(r)
    });

    it('查看用户出资过的项目',async function(){
        const r1 = await loan.connect(investor1).getContributeProjects(investor1.address)
        console.log(r1)
        const r2 = await loan.connect(investor2).getContributeProjects(investor2.address)
        console.log(r2)
    })

    it('查询所有出资单',async function(){
        let r = await loan.connect(owner).contribution(0,0)
        console.log(r)
        r = await loan.connect(owner).contribution(0,1)
        console.log(r)
    })

    

})














