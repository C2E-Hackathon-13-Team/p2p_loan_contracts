// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;
import "hardhat/console.sol";

contract Loan{

    //筹资项目
    struct Project{
        uint256 amount;//金额，以Wei为单位
        uint256 rate;//年利率*1000000,例如如果年利率为5.6789%，则该字段的值 = 0.056789*1000000 = 56789
        uint8 term;//贷款期限，年 
        uint256 collectEndTime;//筹资结束时间
        uint8 repayMethod;//还款方式，1-等额本息、2-待定
        uint8 status;//项目状态：1-筹资期、2-还款期、3-已撤销
        address launcher;//发起人
        uint256 collected;//已筹集到资金
    }

    //还款账单

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

    mapping(address=>uint[]) public launchProjects;//发起过的项目
    mapping(address=>uint[]) public contributeProjects;//出资过的项目



    //新增筹资项目
    function createProject(uint256 _amount,uint256 _rate,uint8 _term,uint256 _collectEndTime,uint8 _repayMethod)  external  {
        
        require(_amount > 0,"amount must bigger than 0");
        require(_term > 0,"term must bigger than 0");
        require(_collectEndTime > block.timestamp + 24 hours,"collect end time must be greater than 24 hours");
        require(_repayMethod == 1,"repay method must be 1");

        Project memory p = Project(
            _amount,
            _rate,
            _term,
            _collectEndTime,
            _repayMethod,
            1,
            msg.sender,
            0
        );
        projects.push(p);
        launchProjects[msg.sender].push(projects.length-1);
        
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

    





}