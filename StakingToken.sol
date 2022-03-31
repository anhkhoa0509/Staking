pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./safeMath.sol";

contract Staking is Ownable {
    using SafeMath for uint256;
  
    address[][] internal stakeholders;
    IERC20 private tokenReward;

    // Address owner contract
    address public admin;
    uint256 public totalDakInContract;

    // Time staking
    mapping(uint256=>mapping(address=>uint256)) internal startStakingTime;
    mapping(uint256=>mapping(address=>uint256)) internal endStakingTime;
    

 
    mapping(uint256=> mapping(address => uint256)) internal stakes;
    
    mapping(uint256=> mapping(address => bool)) internal isStake;

    mapping(uint256=> mapping(address => uint256)) internal rewards;

    mapping(uint256=> mapping(address => uint256)) internal numberReward;

    mapping(address=>uint256) internal totalDak;

    
    mapping(uint256=>mapping(address => uint256)) internal unLocks;
    
    struct Staking{
        address owner;
        uint256 time;
        uint256 totalStakes;
        uint interestRate;
        string typeCoin;
        uint256 id;
        uint256 timeUnlocks;
    }


    Staking[] public Stakings;


      constructor (IERC20 token)  {
        tokenReward = token;
        admin = msg.sender;

    }
    // ---------- STAKES ----------

    
    function createStaking(uint256 _time, uint _interestRate,string memory _typeCoin,uint256 _timeUnlocks) public{
        Stakings.push(
            Staking(msg.sender,_time,0,_interestRate,_typeCoin,Stakings.length,_timeUnlocks)
        );
    }

    function getStaking() public view returns (Staking[] memory){
        Staking[] memory result = new Staking[](Stakings.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < Stakings.length ; i++) {
                result[counter] = Stakings[i];
                counter++;
            }
        return result;
    }

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created, 1 _stake = 0.01 ETH
     *
     */
    function createStake(uint256 _stake,uint256 _id, uint256 _rStake,uint256 _rDak) public payable{
        require( !isStake[_id][msg.sender], "The address is staking");

        require(_stake  > 0 &&  msg.value > 0 && _stake == msg.value, "Cannot staking value 0");

        isStake[_id][msg.sender] = true;
        
        startStakingTime[_id][msg.sender] = block.timestamp;

        endStakingTime[_id][msg.sender] = block.timestamp.add(Stakings[_id].time);
 
        unLocks[_id][msg.sender] = 0;
      
        stakes[_id][msg.sender] = msg.value;

        uint256 sumReward = calculateReward(_stake,_id,_rStake,_rDak);

        numberReward[_id][msg.sender] = sumReward / ((endStakingTime[_id][msg.sender] - startStakingTime[_id][msg.sender])/Stakings[_id].timeUnlocks);
        
        rewards[_id][msg.sender] = sumReward;

        Stakings[_id].totalStakes =  Stakings[_id].totalStakes.add(msg.value);
    }

   
    function addStake(uint256 _stake,uint256 _id, uint256 _rStake,uint256 _rDak) public payable{
        require(_stake  > 0 &&  msg.value > 0 && _stake == msg.value, "Cannot staking value 0");
        require(isStake[_id][msg.sender] , "User not staking");

        stakes[_id][msg.sender] = stakes[_id][msg.sender].add(msg.value);
        
        uint256 sumReward = calculateReward(_stake,_id,_rStake,_rDak);

        uint256 totalCurrentReward = rewards[_id][msg.sender] - numberReward[_id][msg.sender] * unLocks[_id][msg.sender] ;

        rewards[_id][msg.sender] = totalCurrentReward.add(sumReward);

        endStakingTime[_id][msg.sender] = endStakingTime[_id][msg.sender].add(Stakings[_id].time);

        numberReward[_id][msg.sender] = rewards[_id][msg.sender] / 
        ( ((endStakingTime[_id][msg.sender] - startStakingTime[_id][msg.sender])/Stakings[_id].timeUnlocks) - unLocks[_id][msg.sender]);
        
        Stakings[_id].totalStakes = Stakings[_id].totalStakes.add(msg.value);

    }

    function calculateReward(uint256 _stake,uint256 _id, uint256 _rStake,uint256 _rDak) public view returns(uint256){
        return (_stake * _rStake * Stakings[_id].interestRate)/(_rDak*100);
    }



//   function getTimeSuccessReward(address _userAdress,uint256 _id) public view returns (uint256[] memory){
//         uint256[] memory result = new uint256[]();
//         uint256 start =  startStakingTime[_id][_userAdress];
//         uint256 end =  endStakingTime[_id][_userAdress];
//         uint256 temp = (end-start)/Stakings[_id].unlocks;
//         for (uint256 i = 0; i < Stakings[_id].unlocks ; i++) {
//                 start = start.add(temp);
//                 result[i] = start;
//             }
//         return result;
//     }


     function getBalanceStaking(uint256 _id) public view returns(uint){
        return Stakings[_id].totalStakes;
    }

  

    function getBalanceUserStake(address _userAdress,uint256 _id) public view returns(uint){
        return  stakes[_id][_userAdress];
    }


    function getTokenUserReward(address _userAdress,uint256 _id) public view returns(uint){
        return rewards[_id][_userAdress];
    }
  

    
    function getTimeStaking(address _stakeholder,uint256 _id)
        public
        view
        returns (uint256)
    {
        return endStakingTime[_id][_stakeholder];
    }

 
  
    // ---------- REWARDS ----------




    // function getIndexReward(address _userAdress,uint256 _id) public view returns(uint256){
    //     return numberPart[_id][_userAdress];
    // }

    // function getCurrentTimeReward(address _userAdress,uint256 _id) public view returns(uint256){
    //     uint256 result ;
    //     uint256 start =  startStakingTime[_id][_userAdress];
    //     uint256 end =  endStakingTime[_id][_userAdress];
    //     uint256 temp = (end-start)/Stakings[_id].unlocks;
    //     uint256 index =totalReward[_id][_userAdress] - getIndexReward(msg.sender,_id);
    //     for (uint256 i = 0; i <= index ; i++) {
    //             start = start.add(temp);
    //             result = start;
    //         }
    //     return result;
    // }

    function getUserReward(address _userAdress, uint256 _id) public view returns(uint256){
        return  numberReward[_id][_userAdress];
    }


    function withdrawRawardPart(uint256 _id) public {
        require(endStakingTime[_id][msg.sender] > 0, "not staking yet");

        require((endStakingTime[_id][msg.sender] - startStakingTime[_id][msg.sender]) / Stakings[_id].timeUnlocks - 1  > unLocks[_id][msg.sender],
         "the number of times to receive the reward has expired");
      
        uint256 temp = startStakingTime[_id][msg.sender];
        
        require(block.timestamp > temp.add(unLocks[_id][msg.sender]*Stakings[_id].timeUnlocks), "not enough staking time");
        
        uint256 reward = numberReward[_id][msg.sender];

        tokenReward.transferFrom(admin, msg.sender,reward);

        totalDak[msg.sender] = totalDak[msg.sender].add(reward);

        totalDakInContract = totalDakInContract.add(reward);

        unLocks[_id][msg.sender] = unLocks[_id][msg.sender].add(1);
    }

    function getTotalDakReward() public view returns(uint256){
        return totalDakInContract;
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward(uint256 _id) public payable{
        require(endStakingTime[_id][msg.sender] > 0, "not staking yet");
        require(block.timestamp > endStakingTime[_id][msg.sender], "not enough staking time");
        require (unLocks[_id][msg.sender] == ((endStakingTime[_id][msg.sender] - startStakingTime[_id][msg.sender]) / Stakings[_id].timeUnlocks) -1,"You have not received all bonus coins");
        
        uint amountToTransfer = getBalanceUserStake(msg.sender,_id);

        address payable withdrawTo = payable(msg.sender);
        withdrawTo.transfer(amountToTransfer);
        Stakings[_id].totalStakes = Stakings[_id].totalStakes.sub(amountToTransfer);

        uint256 reward = numberReward[_id][msg.sender];

        tokenReward.transferFrom(admin, msg.sender, reward);

        totalDak[msg.sender] = totalDak[msg.sender].add(reward);
        totalDakInContract = totalDakInContract.add(totalDak[msg.sender]);
        
        isStake[_id][msg.sender] = false;
        rewards[_id][msg.sender] = 0;
        stakes[_id][msg.sender] = 0;
        endStakingTime[_id][msg.sender] = 0;
        unLocks[_id][msg.sender] = unLocks[_id][msg.sender].add(1);

    }

   
}
