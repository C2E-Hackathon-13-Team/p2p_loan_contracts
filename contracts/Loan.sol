// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;
import "hardhat/console.sol";

import "./utils/ABDKMath/ABDKMath64x64.sol";

contract Loan{

    //还款账单
    struct Bill{
        uint256 projectId;//项目ID
        uint256 startTime;//生效时间
        uint256 principal;//本金
        uint256 interest;//利息
        uint256 repaid;//已偿还金额
        
    }

    //筹资项目
    struct Project{
        uint256 amount;//金额，以Wei为单位
        uint256 rate;//年利率*1000000,例如如果年利率为5.6789%，则该字段的值 = 0.056789*1000000 = 56789
        uint8 term;//贷款期限，月 
        uint256 collectEndTime;//筹资结束时间
        uint8 repayMethod;//还款方式，1-等额本息、2-待定
        uint8 status;//项目状态：1-筹资期、2-还款期、3-已撤销
        address launcher;//发起人
        uint256 collected;//已筹集到资金
    }

    

    //出资信息
    struct Contribution{
        address investor;//出资人
        uint amount;//出资金额
        uint time;
    }

    mapping(address=>bool) public users;//已注册用户
    mapping(address=>uint256) public creditScore;//信用金

    Project[] public projects;//所有筹资项目
    mapping(uint=>Contribution[]) public contribution;//出资信息
    mapping(uint=>Bill[]) public bills;//还款账单

    mapping(address=>uint[]) public launchProjects;//发起过的项目
    mapping(address=>uint[]) public contributeProjects;//出资过的项目



    //新增筹资项目
    function createProject(uint256 _amount,uint256 _rate,uint8 _term,uint256 _collectEndTime,uint8 _repayMethod)  external  {
        
        // require(_amount > 0,"amount must bigger than 0");
        // require(_term > 0,"term must bigger than 0");
        // require(_collectEndTime > block.timestamp + 24 hours,"collect end time must be greater than 24 hours");
        // require(_repayMethod == 1,"repay method must be 1");


        

        // projects.push(Project(
        //     _amount,
        //     _rate,
        //     _term,
        //     _collectEndTime,
        //     _repayMethod,
        //     1,
        //     msg.sender,
        //     0
        // ));

        // uint pid =projects.length-1;



        // // 转换为定点数
        // int128 amount128 = ABDKMath64x64.fromUInt(_amount);
        // // int128 term128 = ABDKMath64x64.fromUInt(_term);
        // int128 mr128 = ABDKMath64x64.div(ABDKMath64x64.fromUInt(_rate),ABDKMath64x64.fromInt(12));

        // /**
        //  * 每月还款额=[贷款本金×月利率×（1+月利率）^还款月数]÷[（1+月利率）^还款月数－1]
        //  */
        // //（1+月利率）
        // int128 num1 = ABDKMath64x64.add(ABDKMath64x64.fromInt(1),mr128);
        // //（1+月利率）^还款月数
        // int128 num2 = ABDKMath64x64.pow(num1,_term);
        // //贷款本金×月利率
        // int128 num3 = ABDKMath64x64.mul(amount128,mr128);
        // //[贷款本金×月利率×（1+月利率）^还款月数]
        // int128 num4 = ABDKMath64x64.mul(num3,num2);
        // //[（1+月利率）^还款月数－1]
        // int128 num5 = ABDKMath64x64.sub(num2,ABDKMath64x64.fromInt(1));
        // //每月还款额
        // int128 num6 = ABDKMath64x64.div(num4,num5);
        
        // uint payMonth = ABDKMath64x64.toUInt(num6);
        // console.log(payMonth);

        // for(uint m=1;m<=_term;m++){
        //     bills[pid].push(Bill(payMonth,0,0,0,0));
        // }
        
        
         


        // launchProjects[msg.sender].push(pid);

        
    }

    //撤销项目
    function revocateProject(uint pid) external{
        Project storage p = projects[pid];
        require( p.launcher == msg.sender , "Only the project initiator can cancel the project");
        require( p.status == 1 , "Only projects during the funding period can be cancelled");

        Contribution[] storage cons = contribution[pid];
        for (uint256 i = 0; i < cons.length; i++) {
             (bool success, ) = cons[i].investor.call{value:cons[i].amount}("");
             require(success,string.concat("transfer to ",string(abi.encodePacked(cons[i].investor))," fail !"));
        }

        p.status = 3; 
    }

    receive() external payable {}

    //出资
    function contribute(uint pid) external payable {
        Project storage p = projects[pid];
        require( p.status == 1 , "Only projects in the funding phase can receive funding");
        require( p.launcher != msg.sender , "Project launcher are not allowed to contribute capital");
        require( msg.value > 0 ,"Amount must bigger than 0");
        require( msg.value <= p.amount - p.collected ,"The amount of funds contributed exceeds the project requirements");

        contribution[pid].push(Contribution(msg.sender,msg.value,block.timestamp));
        p.collected += msg.value;
        contributeProjects[msg.sender].push(pid);
    }

    //还款
    function repay(uint pid) external payable{
        Project storage p = projects[pid];
        require( p.status == 2 , "Only projects that have entered the repayment period can be repaid.");
        require( p.launcher == msg.sender , "Only the project initiator can repay the loan");


    }

    //获取当前应还金额
    function getAmountNeedRepayNow(uint pid) external view returns(uint256){
        Project storage p = projects[pid];


    }

    using ABDKMath64x64 for bytes16;

    function test() external view returns(int128){

        // 将10和3转换为定点数
        int128 numerator = ABDKMath64x64.fromInt(10);
        int128 denominator = ABDKMath64x64.fromInt(3);
        
        // 进行除法运算
        int128 result = ABDKMath64x64.div(numerator, denominator);

        return ABDKMath64x64.toInt(result);

    }

    





}