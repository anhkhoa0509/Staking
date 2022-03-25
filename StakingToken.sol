
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
    mapping(uint256 => mapping(address => uint256)) balances;
    // Time staking
    mapping(uint256=>mapping(address=>uint256)) internal startStakingTime;
    mapping(uint256=>mapping(address=>uint256)) internal endStakingTime;
    

 
    mapping(uint256=> mapping(address => uint256)) internal stakes;

    mapping(uint256=> mapping(address => uint256)) internal rewards;
    mapping(address=>uint256) internal totalDak;

    
    mapping(uint256=>mapping(address => uint256)) internal numberPart;
    
    struct Staking{
        address owner;
        uint256 time;
        uint256 totalStakes;
        uint interestRate;
        string typeCoin;
    }
    Staking[] public Stakings;


      constructor (IERC20 token)  {
        tokenReward = token;
        admin = msg.sender;

    }
    // ---------- STAKES ----------

    
    function createStaking(uint256 _time, uint _interestRate) public{
        Stakings.push(
            Staking(msg.sender,_time,0,_interestRate,"ETH")
        );
    }

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created, 1 _stake = 0.01 ETH
     *
     */
    function createStake(uint256 _stake,uint256 _id) public payable{
        uint stake = _stake * 10 ** 16;

        require(_stake  > 0 &&  msg.value > 0 && stake == msg.value, "Cannot staking value 0");

        numberPart[_id][msg.sender] = 1;

        startStakingTime[_id][msg.sender] = block.timestamp;

        endStakingTime[_id][msg.sender] = block.timestamp.add(Stakings[_id].time);

        rewards[_id][msg.sender] = calculateReward(stake,Stakings[_id].time,Stakings[_id].interestRate);

        Stakings[_id].totalStakes =  Stakings[_id].totalStakes.add(msg.value);
        
        stakes[_id][msg.sender] = stakes[_id][msg.sender].add(_stake);
    }

  
     function getBalanceStaking(uint256 _id) public view returns(uint){
        return Stakings[_id].totalStakes;
    }

  

    function getBalanceUserStake(address _userAdress,uint256 _id) public view returns(uint){
        return  balances[_id][_userAdress];
    }


    function getUserReward(address _userAdress,uint256 _id) public view returns(uint){
        return stakes[_id][msg.sender] ;
    }
  


    
    function getTimeStaking(address _stakeholder,uint256 _id)
        public
        view
        returns (uint256)
    {
        return endStakingTime[_id][_stakeholder];
    }

 
  
    // ---------- REWARDS ----------

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    // function totalRewards() public view returns (uint256) {
    //     uint256 _totalRewards = 0;
    //     for (uint256 s = 0; s < stakeholders.length; s += 1) {
    //         _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
    //     }
    //     return _totalRewards;
    // }

    // /**
    //  * @notice A simple method that calculates the rewards for each stakeholder.
    //  * @param _stakeholder The stakeholder to calculate rewards for.
    //  */

    function calculateReward(uint256 _amount,uint256 _time,uint _interestRate) public view returns(uint){
        if (_amount < 10) {
            return _interestRate * 10**18;
        }
        if (
            _amount >= 10 && _amount < 50
        ) {
            return _interestRate*2* 10**18;
        }
        else{
            return _interestRate*3* 10**18;
        }
    }

    // /**
    //  * @notice A method to distribute rewards to all stakeholders.
    //  */
    // function distributeRewards() public onlyOwner {
    //     for (uint256 s = 0; s < stakeholders.length; s += 1) {
    //         address stakeholder = stakeholders[s];
    //         uint256 reward = calculateReward(stakeholder);
    //         rewards[stakeholder] = rewards[stakeholder].add(reward);
    //     }
    // }

    function withdrawRawardPart(uint256 _id) public {
        require(endStakingTime[_id][msg.sender] > 0, "not staking yet");

        uint256 time = numberPart[_id][msg.sender]*(endStakingTime[_id][msg.sender] - startStakingTime[_id][msg.sender])/3;
      
        uint256 currentTime = startStakingTime[_id][msg.sender].add(time);
       
        require(numberPart[_id][msg.sender] < 3, "the number of times to receive the reward has expired");
       
        require(block.timestamp > currentTime, "not enough staking time");
      
        numberPart[_id][msg.sender] = numberPart[_id][msg.sender].add(1);
        
        tokenReward.transferFrom(admin, msg.sender, rewards[_id][msg.sender]/3);

        totalDak[msg.sender] = totalDak[msg.sender].add(rewards[_id][msg.sender]/3);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward(uint256 _id) public payable{
        require(endStakingTime[_id][msg.sender] > 0, "not staking yet");
        require(block.timestamp > endStakingTime[_id][msg.sender], "not enough staking time");
        uint amountToTransfer = getBalanceUserStake(msg.sender,_id);
        balances[_id][msg.sender] = 0;
        numberPart[_id][msg.sender] = 3;

        address payable withdrawTo = payable(msg.sender);
        withdrawTo.transfer(amountToTransfer);

        tokenReward.transferFrom(admin, msg.sender, rewards[_id][msg.sender]/3 * 10**18);

       
        rewards[_id][msg.sender] = 0;
        stakes[_id][msg.sender] = 0;
        endStakingTime[_id][msg.sender] = 0;
    }

   
}
