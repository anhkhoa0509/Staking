pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./safemath.sol";

contract DakToken is ERC20, Ownable {
    using SafeMath for uint256;
    /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;

    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => uint256) internal stakes;

    mapping(address => uint256) internal timestaking;

    mapping(address => uint256) internal timestaked;

    /**
     * @notice The accumulated rewards for each stakeholder.
     */
    mapping(address => uint256) internal rewards;

    constructor() ERC20("DAKSHOW", "DAK") {
        _mint(msg.sender, 1000);
    }

    // ---------- STAKES ----------

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake, uint256 _time) public {
        require(_stake > 0, "Cannot staking value 0");
        _burn(msg.sender, _stake);
        timestaked[msg.sender] = block.timestamp.add(_time);
        timestaking[msg.sender] = _time;
        if (stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
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
        timestaking[msg.sender] = 0;
        timestaked[msg.sender] = 0;
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
        return timestaked[_stakeholder];
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

    /**
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder)
        public
        view
        returns (uint256)
    {
        if (timestaking[_stakeholder] < 60) {
            return stakes[_stakeholder] / 10;
        }
        if (
            timestaking[_stakeholder] >= 60 && timestaking[_stakeholder] < 180
        ) {
            return stakes[_stakeholder] / 5;
        }
        if (timestaking[_stakeholder] >= 300) {
            return (3 * stakes[_stakeholder]) / 10;
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

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() public {
        require(block.timestamp > timestaked[msg.sender], "not enough staking time");
        uint256 reward = calculateReward(msg.sender);
        _mint(msg.sender, stakes[msg.sender] + reward);
        removeStakeholder(msg.sender);
        rewards[msg.sender] = 0;
        stakes[msg.sender] = 0;
        timestaked[msg.sender] = 0;
    }

    function issueToken() public onlyOwner {
        _mint(msg.sender, 1000 * 10**18);
    }
}
