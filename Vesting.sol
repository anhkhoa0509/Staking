pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./safeMath.sol";

contract Vesting is Ownable {
    using SafeMath for uint256;
  
    address[][] internal stakeholders;
    IERC20 private tokenReward;

    // Address owner contract
    address public admin;
    uint256 public totalDakInContract;

    // Time Vesting
    mapping(uint256=>mapping(address=>uint256)) internal startVestingTime;

    mapping(uint256=>mapping(address=>uint256)) internal endVestingTime;
    

 
    mapping(uint256=> mapping(address => uint256)) internal stakes;
    
    mapping(uint256=> mapping(address => bool)) internal isStake;

    mapping(uint256=> mapping(address => uint256)) internal rewards;

    mapping(address=>uint256) internal totalDak;

    
    mapping(uint256=>mapping(address => uint256)) internal unLocks;
    
    struct Vesting{
        address owner;
        uint256 time;
        uint256 totalStakes;
        uint interestRate;
        string typeCoin;
        uint256 id;
        uint256 totalUser;
    }


    Vesting[] public Vestings;


      constructor (ERC20 token)  {
        tokenReward = token;
        admin = msg.sender;

    }
    // ---------- STAKES ----------

    
    function createVesting(uint256 _time, uint _interestRate,string memory _typeCoin) public{
        Vestings.push(
            Vesting(msg.sender,_time,0,_interestRate,_typeCoin,Vestings.length,0)
        );
    }

    function getVesting() public view returns (Vesting[] memory){
        Vesting[] memory result = new Vesting[](Vestings.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < Vestings.length ; i++) {
                result[counter] = Vestings[i];
                counter++;
            }
        return result;
    }


    function getTimeSuccessReward(address _userAdress,uint256 _id) public view returns (uint256){
        return endVestingTime[_id][_userAdress];
    }

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created, 1 _stake = 0.01 ETH
     *
     */

    

    function createStake(uint256 _stake,uint256 _id) public payable{
        require( !isStake[_id][msg.sender], "The address is Vesting");
        require(_stake  > 0 , "Cannot Vesting value 0");    
    
        isStake[_id][msg.sender] = true;
    
        tokenReward.transferFrom(msg.sender, admin, _stake);

        startVestingTime[_id][msg.sender] = block.timestamp;

        endVestingTime[_id][msg.sender] = block.timestamp + Vestings[_id].time;
      
        stakes[_id][msg.sender] = _stake;

        rewards[_id][msg.sender] = calculateReward(_stake,_id);
         Vestings[_id].totalStakes = Vestings[_id].totalStakes.add(_stake);

        Vestings[_id].totalUser =  Vestings[_id].totalUser.add(1);
    }




    function geTotaltUserInVesting(uint256 _id) public view returns(uint256){
        return Vestings[_id].totalUser;
    }


    function calculateReward(uint256 _stake,uint256 _id)
     public view returns(uint256){
        return _stake * Vestings[_id].interestRate / 100;
    }


     function getBalanceVesting(uint256 _id) public view returns(uint256){
        return Vestings[_id].totalStakes;
    }

  

    function getBalanceUserStake(address _userAdress,uint256 _id) public view returns(uint){
        return  stakes[_id][_userAdress];
    }


    function getTokenUserReward(address _userAdress,uint256 _id) public view returns(uint){
        return rewards[_id][_userAdress];
    }
  

 
  
    // ---------- REWARDS ----------



    function getUserReward(address _userAdress, uint256 _id) public view returns(uint256){
        return  rewards[_id][_userAdress];
    }

    function timeStaked(address _userAdress, uint256 _id) public view returns(uint256){
       return endVestingTime[_id][_userAdress];
    }

    function getTotalDakReward() public view returns(uint256){
        return totalDakInContract;
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward(uint256 _id) public payable{
        require(isStake[_id][msg.sender], "not Vesting yet");

        require(block.timestamp > endVestingTime[_id][msg.sender], "not enough Vesting time");

        uint amountToTransfer = stakes[_id][msg.sender];
      
        uint256 reward = rewards[_id][msg.sender];

        uint256 totalWithraw = amountToTransfer.add(reward);

        tokenReward.transferFrom(admin, msg.sender, totalWithraw);

     Vestings[_id].totalStakes = Vestings[_id].totalStakes.sub(amountToTransfer);
        
        isStake[_id][msg.sender] = false;
        rewards[_id][msg.sender] = 0;
        stakes[_id][msg.sender] = 0;
        endVestingTime[_id][msg.sender] = 0;
        unLocks[_id][msg.sender] = 0;
        Vestings[_id].totalUser =  Vestings[_id].totalUser - 1;

    }

   
}
