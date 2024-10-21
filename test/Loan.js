const {ethers} = require("hardhat");


describe("贷款合约",async function(){

    let loan;

    before(async function () {
        const Loan = await ethers.getContractFactory("Loan");
        loan = await Loan.deploy();
    });

    it("新增筹资项目", async function () {
        var p = await loan.createProject(
            500000000000000000,40000,10,1732193392,1
        );
        console.log(p);
        var bs = await loan.bills(0,0)
        console.log(bs);
        
    });
})