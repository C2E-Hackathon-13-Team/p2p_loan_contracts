const {ethers} = require("hardhat");


describe("贷款合约",async function(){

    let loan;

    before(async function () {
        console.log("11111111")
        const Loan = await ethers.getContractFactory("Loan");
        loan = await Loan.deploy();
        console.log("22222222")
    });

    it("新增筹资项目", async function () {
        var p = await loan.createProject(
            100,40000,10,1729568530000,1
        );
        console.log(p);
        var bs = await loan.bills(0,0)
        console.log(bs);
        
    });
})