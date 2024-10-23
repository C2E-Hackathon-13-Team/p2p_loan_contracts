// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;
import "hardhat/console.sol";

import "./utils/ABDKMath/ABDKMath64x64.sol";
import "./utils/BokkyPooBahsDateTime/BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Loan is Ownable{

    //owner会抽取手续费，功能后期在加
    constructor(address initialOwner) Ownable(initialOwner) {}
    

    //还款账单
    struct Bill{
        uint256 projectId;//项目ID
        uint256 repayTime;//账单生效日期
        uint256 principal;//需要偿还的本金
        uint256 interest;//需要偿还的利息
        uint256 repaid;//已偿还金额
        uint256 status;//偿还状态：1-未清偿 2-已清偿
        
    }

    //筹资项目
    struct Project{
        uint256 amount;//金额，以Wei为单位
        uint256 rate;//年利率*1000000,例如如果年利率为5.6789%，则该字段的值 = 0.056789*1000000 = 56789
        uint256 term;//贷款期限，月 
        uint256 collectEndTime;//筹资结束时间
        uint8 repayMethod;//还款方式，1-等额本息、2-待定
        uint8 status;//项目状态：1-筹资期（或待确认）、2-还款期、3-已结束、4-已撤销
        address launcher;//发起人
        uint256 collected;//已筹集到资金
        uint256 currentBill;//从第几个账单开始还款
    }

    //出资信息
    struct Contribution{
        address investor;//出资人
        uint amount;//出资金额
        uint time;//出资时间
        uint repaid;//已偿还
    }

    mapping(address=>bool) public users;//已注册用户
    mapping(address=>uint256) public creditScore;//信用金

    Project[] public projects;//所有筹资项目
    mapping(uint=>Contribution[]) public contribution;//出资信息
    mapping(uint=>Bill[]) public bills;//还款账单

    mapping(address=>uint[]) public launchProjects;//发起过的项目
    mapping(address=>uint[]) public contributeProjects;//出资过的项目

    receive() external payable {}

    //新增项目
    function createProject(uint256 _amount,uint256 _rate,uint256 _term,uint256 _collectEndTime,uint8 _repayMethod)  external  {
        
        require(_amount > 0,"amount must bigger than 0");
        require(_term > 0,"term must bigger than 0");
        require(_collectEndTime > block.timestamp + 24 hours,"collect end time must be greater than 24 hours");
        require(_repayMethod == 1,"repay method must be 1");

        projects.push(Project(
            _amount,
            _rate,
            _term,
            _collectEndTime,
            _repayMethod,
            1,
            msg.sender,
            0,
            0
        ));
        uint pid =projects.length-1;
        launchProjects[msg.sender].push(pid);
        
    }

    //出资
    function contribute(uint pid) external payable {
        Project storage p = projects[pid];
        require( p.status == 1 && block.timestamp < p.collectEndTime, "Only projects in the funding phase can receive funding");
        require( p.launcher != msg.sender , "Project launcher are not allowed to contribute capital");
        require( msg.value > 0 ,"Amount must bigger than 0");
        require( msg.value <= p.amount - p.collected ,"The amount of funds contributed exceeds the project requirements");

        contribution[pid].push(Contribution(msg.sender,msg.value,block.timestamp,0));
        p.collected += msg.value;
        contributeProjects[msg.sender].push(pid);
    }

    //撤销项目
    function revocateProject(uint pid) external{
        Project storage p = projects[pid];
        require( p.launcher == msg.sender , "Only the project initiator can cancel the project");
        require( p.status == 1 , "Only projects in the funding period and pending confirmation stage can be cancelled");

        Contribution[] storage cons = contribution[pid];
        for (uint256 i = 0; i < cons.length; i++) {
             (bool success, ) = cons[i].investor.call{value:cons[i].amount}("");
             require(success,string.concat("transfer to ",string(abi.encodePacked(cons[i].investor))," fail !"));
        }

        p.status = 4; 
    }


    //确认项目。进入还款期,发放贷款,并生成账单
    function confirm(uint pid) external {


        Project storage pro = projects[pid];
        require( pro.status == 1 && block.timestamp > pro.collectEndTime , "Confirmation operations can only be performed when the project is in a pending confirmation state");
        require( pro.launcher == msg.sender , "Only the initiator can confirm the project");
        require( pro.collected > 0 , "Only projects with raised funds greater than 0 can be confirmed");
        pro.status = 2;


        // 转换为定点数
        int128 amount128 = ABDKMath64x64.fromUInt(pro.collected);
        int128 yearRate128 = ABDKMath64x64.div(ABDKMath64x64.fromUInt(pro.rate),ABDKMath64x64.fromUInt(1000000));//月利率
        int128 mr128 = ABDKMath64x64.div(yearRate128,ABDKMath64x64.fromInt(12));//月利率

        //每月还款额
        int128 num6 = getRepayMonthly(amount128,mr128,pro.term);
        // uint repayMonthly = ABDKMath64x64.toUInt(num6);

        
        Bill[] storage bs = bills[pid];
        int128 remaining = amount128;//剩余本金
        for(uint m=1 ; m <=pro.term ; m++){
            

            //当期应还利息
            int128 num7 = ABDKMath64x64.mul(remaining,mr128);

            //当期应还本金
            int128 num8 = ABDKMath64x64.sub(num6,num7);


            // 【考虑精度影响】如果这是最后一期，还有本金没还不完，当期应还本金就应该等于剩余本金
            if(m == pro.term && ABDKMath64x64.toInt(remaining) > ABDKMath64x64.toInt(num8) ){//之前还少了，最后补足一下

                num8 = remaining;
                remaining = ABDKMath64x64.fromInt(0);

            }else{//之前还多了，这次少还一点

                //【考虑精度影响】如果应还本金超过了剩余本金，说明这一次就要还完所有钱了，要把应还本金设为剩余本金，然后下一轮的剩余本金置零，而不是算出负数来
                remaining = ABDKMath64x64.sub(remaining , num8);
                if(ABDKMath64x64.toInt(remaining) < 0){
                    num8 = remaining;
                    remaining = ABDKMath64x64.fromInt(0);
                }

            }


            //还款日期
            uint repayTime = BokkyPooBahsDateTimeLibrary.addMonths(pro.collectEndTime,m);

            //存入账单
            bs.push(Bill(
                pid,
                repayTime,
                ABDKMath64x64.toUInt(num8),
                ABDKMath64x64.toUInt(num7),
                0,
                1
            ));


        }


        (bool success, ) = msg.sender.call{value:pro.collected}("");
        require(success,"Failure to issue loan");
        
    }

    /**
    * 每月还款额=[贷款本金×月利率×（1+月利率）^还款月数]÷[（1+月利率）^还款月数－1]
    * 返回定点数
    */
    function getRepayMonthly(int128 amount128,int128 mr128,uint256 _term) private pure returns(int128){

        //（1+月利率）
        int128 num1 = ABDKMath64x64.add(ABDKMath64x64.fromInt(1),mr128);
        //（1+月利率）^还款月数
        int128 num2 = ABDKMath64x64.pow(num1,_term);
        //贷款本金×月利率
        int128 num3 = ABDKMath64x64.mul(amount128,mr128);
        //[贷款本金×月利率×（1+月利率）^还款月数]
        int128 num4 = ABDKMath64x64.mul(num3,num2);
        //[（1+月利率）^还款月数－1]
        int128 num5 = ABDKMath64x64.sub(num2,ABDKMath64x64.fromInt(1));
        //每月还款额
        int128 num6 = ABDKMath64x64.div(num4,num5);

        return num6;
    }

    //还款
    function repay(uint pid) external payable{
        Project storage p = projects[pid];
        require( p.status == 2 , "Only projects that have entered the repayment period can be repaid.");
        require( p.launcher == msg.sender , "Only the project initiator can repay the loan");
        require( msg.value > 0 , "Not carrying Ethereum");
        
        //更新账单和项目状态
        uint msgVal = msg.value;
        uint _currentBill = p.currentBill;
        Bill[] storage bs = bills[pid];
        for( uint i = p.currentBill ; i < bs.length ; i++ ){
            if(block.timestamp < bs[i].repayTime || msgVal == 0){
                break;
            }else{
                uint needRepy = bs[i].principal + bs[i].interest - bs[i].repaid;

                if(needRepy > msgVal){
                    bs[i].repaid += msgVal;
                    msgVal = 0;
                }else{
                    bs[i].repaid += needRepy;
                    msgVal -= needRepy;
                    _currentBill++;
                    bs[i].status = 2;
                }
            }
        }
        p.currentBill = _currentBill;
        if(_currentBill == bs.length) p.status = 3;


        //转账至出资人
        uint totalRepay = msg.value - msgVal;
        if(totalRepay > 0){
            Contribution[] storage cons = contribution[pid];
            for( uint i = 0 ; i < cons.length ; i++ ){
                uint money = totalRepay * ( cons[i].amount /  p.collected ) ;
                (bool success, ) = cons[i].investor.call{value:money}("");
                require(success,"Failed to repay funds to investors");
            }
        }


        //退还多余金额
        if(msgVal!=0){
            (bool success, ) = msg.sender.call{value:msgVal}("");
            require(success,"Refund of excess amount failed");
        }

    }

    //获取项目所有还款账单
    function getBillsByPid(uint pid) external view returns(Bill[] memory){
        return bills[pid];
    }


    //获取当前需要还金额
    function getAmountNeedRepayNow(uint pid,uint current) public view returns(uint256){
        Project memory pro = projects[pid];
        Bill[] memory bs = bills[pid];

        uint needRepy = 0 ;
        for(uint i=pro.currentBill;i<bs.length;i++){
            if(current < bs[i].repayTime){
                break;
            }else{
                needRepy += bs[i].principal + bs[i].interest - bs[i].repaid;
            }
        }

        return needRepy;

    }

    

}