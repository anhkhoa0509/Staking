pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./safeMath.sol";

contract DakToken is ERC20, Ownable {
    using SafeMath for uint256;
  
    address[] internal stakeholders;
    uint public toltalBalances;

    mapping(address=>uint) internal balances;
    mapping(address=>uint) internal startStakingTime;
    mapping(address=>uint) internal endStakingTime;

 
    mapping(address => uint256) internal stakes;


    mapping(address => uint256) internal rewards;
    
    mapping(address => uint256) internal numberPart;

    constructor() ERC20("DAKSHOW", "DAK") {
        _mint(msg.sender, 0);
    }

    // ---------- STAKES ----------

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created, 1 _stake = 0.01 ETH
     *
     */
    function createStake(uint256 _stake, uint256 _time) public payable{
        uint stake = _stake * 10 ** 16;
        require(_stake  > 0 &&  msg.value > 0 && stake == msg.value, "Cannot staking value 0");
        balances[msg.sender] = msg.value;
        numberPart[msg.sender] = 1;
        startStakingTime[msg.sender] = block.timestamp;
        endStakingTime[msg.sender] = block.timestamp.add(_time);
        rewards[msg.sender] = calculateReward(stake,_time);
        toltalBalances = toltalBalances + msg.value;
        if (stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    function getContractBalance() public view returns(uint){
        return toltalBalances;
    }

  

    function getBalance(address userAdress) public view returns(uint){
        uint value = balances[userAdress];
        // uint time = block.timestamp - depositTime[userAdress];
        // return value + uint((value*7+time)/(100*365*24*60*62)) +1;
        return value;
    }

    function getReward(address userAdress) public view returns(uint){
        return rewards[userAdress];
    }
  

    function addMoneyToContract() public payable{
        toltalBalances+= msg.value;
    }


    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder) public {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

  
    function removeStake() public {
        // uint256 time = (timestaked[msg.sender] - block.timestamp);
        // uint256 reward = (time * stakes[msg.sender]) / 1000;
        uint256 reward = 2;
        uint256 stake = stakes[msg.sender];
        stakes[msg.sender] = stakes[msg.sender].sub(stake);
        endStakingTime[msg.sender] = 0;
      
        if (stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, stake + reward);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder) public view returns (uint256) {
        return stakes[_stakeholder];
    }

    function getTimeStaking(address _stakeholder)
        public
        view
        returns (uint256)
    {
        return endStakingTime[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder,
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s++) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
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

    function calculateReward(uint256 _amount,uint _time) public view returns(uint){
        if (_time < 60) {
            return _amount/ 10;
        }
        if (
            _time >= 60 && _time < 180
        ) {
            return _amount/ 5;
        }
        else{
            return (3 * _amount) / 10;
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

    function withdrawRawardPart() public {
        uint256 time = numberPart[msg.sender]*(endStakingTime[msg.sender] - startStakingTime[msg.sender])/4;
        uint256 currentTime = startStakingTime[msg.sender].add(time);
        require(numberPart[msg.sender] < 4, "the number of times to receive the reward has expired");
        require(block.timestamp > currentTime, "not enough staking time");
        numberPart[msg.sender] = numberPart[msg.sender].add(1);
        _mint(msg.sender,  rewards[msg.sender]/4);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public payable{
        require(block.timestamp > endStakingTime[msg.sender], "not enough staking time");
        address payable withdrawTo = payable(msg.sender);
        uint amountToTransfer = getBalance(msg.sender);
        withdrawTo.transfer(amountToTransfer);
        toltalBalances = toltalBalances - amountToTransfer;
        balances[msg.sender] = 0;
        numberPart[msg.sender] = 4;
        _mint(msg.sender,  rewards[msg.sender]/4);
        removeStakeholder(msg.sender);
        rewards[msg.sender] = 0;
        stakes[msg.sender] = 0;
        endStakingTime[msg.sender] = 0;
    }

    function issueToken() public onlyOwner {
        _mint(msg.sender, 1000 * 10**18);
    }
}
