const {ethers} = require("hardhat");


describe("贷款合约",async function(){

    let loan;

    before(async function () {
        const Loan = await ethers.getContractFactory("Loan");
        loan = await Loan.deploy();
    });

    it("新增筹资项目", async function () {
        //500000000000000000
        const largeNumber = BigInt(500000000000000000);
        await loan.createProject(
            largeNumber ,60000,240,1732193392,1,{
                gasLimit: 30000000
            }
        );

        var bills = await loan.getBillsByPid(0)
        bills.forEach((bill)=>{
            console.log(bill[1],Number(bill[2]/10000000000n),Number(bill[3]/10000000000n));
        })
        
        
    });
})