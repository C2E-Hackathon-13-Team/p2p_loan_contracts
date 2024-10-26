
import { expect } from "chai";
import hre from "hardhat";
import * as fs from "fs";
import * as path from "path"




interface DeployedAddresses {
    [key: string]: string; 
}


describe("Loan", function () {

    this.timeout( 5 * 60 * 1000 );

    let loan;
    let owner;
    let lancher;
    let investor1;
    let investor2;
    let amount:BigInt     = 300n;
    let halfAmount:BigInt = 150n;

    

    before(async function () {
        let chainId = hre.network.config.chainId
        let filePath = path.join(__dirname, '../ignition/deployments/chain-'+chainId+'/deployed_addresses.json')
        const data = fs.readFileSync( filePath , "utf8" );
        let deployedAddr:DeployedAddresses = JSON.parse(data);
        loan = await hre.ethers.getContractAt('Loan',deployedAddr['LockModule#Loan']);
        [owner,lancher,investor1,investor2] = await hre.ethers.getSigners();
        

    })




    it("新增项目", async function () {
        let current = Math.floor(Date.now() / 1000);
        current += 25 * 60 *60;
        const r = await loan.connect(lancher).createProject( amount , 0.06*1000000 , 5 , current , 1 )
        console.log(r)
    });

    it("出资", async function () {
        const r1 = await loan.connect(investor1).contribute(0,{ value: halfAmount })
        console.log(r1)
        const r2 = await loan.connect(investor2).contribute(0,{ value: halfAmount })
        console.log(r2)
    });

    it("确认", async function () {
        const r1 = await loan.connect(lancher).confirm(0,{gasLimit: 30000000})
        console.log(r1)
    });

    it("还款", async function () {
        console.log("等待还款中，请稍后……")

        let flg=true
        loan.on("Repay", ( pid, addr, totalRepay,status) => {
            console.log(`用户 ${addr} 成功在项目 ${pid} 中还款 ${totalRepay} Wei以太币`);
            flg = status != 3;
        });


        while(flg){
            try {
                
                await loan.connect(lancher).repay(0,{ value: halfAmount })
                
            } catch (error) {
                
            } finally {
                await new Promise(resolve => setTimeout(resolve, 2000))
            }
        }

         console.log("=====================已全部还清============================")
        

        
    });

    it('查询项目',async function(){
        let r = await loan.projects(0)
        console.log(r)
    })

    it("查看账户余额", async function () {
        console.log('loan balance = ',await hre.ethers.provider.getBalance(owner.address));
        console.log('owner balance = ',await hre.ethers.provider.getBalance(owner.address));
        console.log('lancher balance = ',await hre.ethers.provider.getBalance(lancher.address));
        console.log('investor1 balance = ',await hre.ethers.provider.getBalance(investor1.address));
        console.log('investor2 balance = ',await hre.ethers.provider.getBalance(investor2.address));
    });


    it.only("查看用户发起过的项目", async function () {
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














