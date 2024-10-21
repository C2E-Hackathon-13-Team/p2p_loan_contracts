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
        uint8 status;//项目状态 ， 1-筹资期、2-还款期
    }

    mapping(address=>bool) public users;//已注册用户
    mapping(address=>uint256) public creditScore;//信用金

    Project[] public projects;//所有筹资项目
    mapping(address=>Project[]) public launchProjects;//发起的项目
    mapping(address=>Project[]) public contributeProjects;//出资的项目



    //新增筹资项目
    function createProject(uint256 _amount,uint256 _rate,uint8 _term,uint256 _collectEndTime,uint8 _repayMethod) 
        external pure returns (Project memory){
        Project memory p = Project(
            _amount,
            _rate,
            _term,
            _collectEndTime,
            _repayMethod,
            1
        );
        return p ;
        
    }

    //撤销项目

    //出资

    //还款

    





}