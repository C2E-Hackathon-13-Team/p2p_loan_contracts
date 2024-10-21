const {ethers} = require("hardhat");


describe("贷款合约",async function(){

    let loan;

    before(async function () {
        const Loan = await ethers.getContractFactory("Loan");
        loan = await Loan.deploy();
    });

    it("新增筹资项目", async function () {
        var p = await loan.createProject(
            100,40000,10,1729568530000,1
        );
        console.log(p);
        console.log("sfdasdfa")
    });
})