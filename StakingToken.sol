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
    mapping(uint256=> mapping(address => uint256)) internal totalReward;

    mapping(address=>uint256) internal totalDak;

    
    mapping(uint256=>mapping(address => uint256)) internal numberPart;
    
    struct Staking{
        address owner;
        uint256 time;
        uint256 totalStakes;
        uint interestRate;
        string typeCoin;
        uint256 id;
        uint8 unlocks;
    }


    Staking[] public Stakings;


      constructor (IERC20 token)  {
        tokenReward = token;
        admin = msg.sender;

    }
    // ---------- STAKES ----------

    
    function createStaking(uint256 _time, uint _interestRate,string memory _typeCoin,uint8 _unlocks) public{
        Stakings.push(
            Staking(msg.sender,_time,0,_interestRate,_typeCoin,Stakings.length,_unlocks)
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
    function createStake(uint256 _stake,uint256 _id) public payable{
        uint stake = _stake * 10 ** 16;

        require(_stake  > 0 &&  msg.value > 0 && stake == msg.value, "Cannot staking value 0");

        isStake[_id][msg.sender] = true;
        
        numberPart[_id][msg.sender] = Stakings[_id].unlocks - 1;
        totalReward[_id][msg.sender] = Stakings[_id].unlocks;

        startStakingTime[_id][msg.sender] = block.timestamp;

        endStakingTime[_id][msg.sender] = block.timestamp.add(Stakings[_id].time);
        stakes[_id][msg.sender] = msg.value;

        rewards[_id][msg.sender] = Stakings[_id].interestRate * stakes[_id][msg.sender] ;

        Stakings[_id].totalStakes =  Stakings[_id].totalStakes.add(msg.value);
    
    }

    function addStake(uint256 _stake,uint256 _id) public payable{
        require(isStake[_id][msg.sender] , "User not staking");
        stakes[_id][msg.sender] = stakes[_id][msg.sender].add(msg.value);
        rewards[_id][msg.sender] = Stakings[_id].interestRate* stakes[_id][msg.sender] ;
        endStakingTime[_id][msg.sender] = endStakingTime[_id][msg.sender].add(Stakings[_id].time);
        numberPart[_id][msg.sender] = numberPart[_id][msg.sender].add(Stakings[_id].unlocks - 1);
        totalReward[_id][msg.sender] = totalReward[_id][msg.sender].add(Stakings[_id].unlocks);

    }



  function getTimeSuccessReward(address _userAdress,uint256 _id) public view returns (uint256[] memory){
        uint256[] memory result = new uint256[](Stakings[_id].unlocks);
        uint256 start =  startStakingTime[_id][_userAdress];
        uint256 end =  endStakingTime[_id][_userAdress];
        uint256 counter = 0;
        uint256 temp = (end-start)/Stakings[_id].unlocks;
        for (uint256 i = 0; i < Stakings[_id].unlocks ; i++) {
                start = start.add(temp);
                result[i] = start;
            }
        return result;
    }


     function getBalanceStaking(uint256 _id) public view returns(uint){
        return Stakings[_id].totalStakes;
    }

  

    function getBalanceUserStake(address _userAdress,uint256 _id) public view returns(uint){
        return  stakes[_id][_userAdress];
    }


    function getUserReward(address _userAdress,uint256 _id) public view returns(uint){
        return rewards[_id][_userAdress] ;
    }
  

    
    function getTimeStaking(address _stakeholder,uint256 _id)
        public
        view
        returns (uint256)
    {
        return endStakingTime[_id][_stakeholder];
    }

 
  
    // ---------- REWARDS ----------




    function getIndexReward(address _userAdress,uint256 _id) public view returns(uint256){
        return numberPart[_id][_userAdress];
    }

    function getCurrentTimeReward(address _userAdress,uint256 _id) public view returns(uint256){
        uint256 result ;
        uint256 start =  startStakingTime[_id][_userAdress];
        uint256 end =  endStakingTime[_id][_userAdress];
        uint256 counter = 0;
        uint256 temp = (end-start)/Stakings[_id].unlocks;
        uint256 index =totalReward[_id][_userAdress] - getIndexReward(msg.sender,_id);
        for (uint256 i = 0; i <= index ; i++) {
                start = start.add(temp);
                result = start;
            }
        return result;

    }

    function withdrawRawardPart(uint256 _id) public {
        require(endStakingTime[_id][msg.sender] > 0, "not staking yet");

        uint256 currentTime = getCurrentTimeReward(msg.sender,_id);
       
        require(numberPart[_id][msg.sender] > 0, "the number of times to receive the reward has expired");
       
        require(block.timestamp > currentTime, "not enough staking time");
      
        numberPart[_id][msg.sender] = numberPart[_id][msg.sender].sub(1);
        
        tokenReward.transferFrom(admin, msg.sender, rewards[_id][msg.sender]/totalReward[_id][msg.sender] );

        totalDak[msg.sender] = totalDak[msg.sender].add(rewards[_id][msg.sender]/totalReward[_id][msg.sender]);

        totalDakInContract = totalDakInContract.add(rewards[_id][msg.sender]/totalReward[_id][msg.sender]);
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
        uint amountToTransfer = getBalanceUserStake(msg.sender,_id);

        address payable withdrawTo = payable(msg.sender);
        withdrawTo.transfer(amountToTransfer);

        Stakings[_id].totalStakes = Stakings[_id].totalStakes.sub(amountToTransfer);
        
        tokenReward.transferFrom(admin, msg.sender, (rewards[_id][msg.sender]*totalReward[_id][msg.sender])/Stakings[_id].unlocks );

        totalDak[msg.sender] = totalDak[msg.sender].add(rewards[_id][msg.sender]/Stakings[_id].unlocks);
        totalDakInContract = totalDakInContract.add(totalDak[msg.sender]);
        
        isStake[_id][msg.sender] = false;
        numberPart[_id][msg.sender] = 0;
        rewards[_id][msg.sender] = 0;
        stakes[_id][msg.sender] = 0;
        endStakingTime[_id][msg.sender] = 0;
    }

   
}
