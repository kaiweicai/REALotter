//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IERC20.sol";
// import "./libraries/RandomNumber.sol";

contract TickerContract is OwnableUpgradeable {
    IERC20 public payToken; // is REA token to buy the ticker
    mapping(address => bool) public isManager;

    mapping(address => mapping(uint256 => Ticker)) public userTickMap;

    uint public rewardMul = 2; //reward mutiple

    uint tickerIndex = 0;

    //onlyManager
    modifier onlyManager() {
        require(isManager[msg.sender], "Not manager");
        _;
    }

    function initialize(address _payToken) public initializer {
        payToken = IERC20(_payToken);
        __Ownable_init();

        isManager[msg.sender] = true;
    }

    struct Ticker {
        address buyer;
        uint256 minerLevel;
        uint256 payAmount;
        bool isUsed;
        uint256 multiple;
    }

    event TickerBuy(address indexed buyer, uint256 minerLevel, uint256 payAmount,uint index);
    event DestoryTicker(address indexed buyer, uint256 index);
    event RewardTicker(address indexed buyer,uint256 rewardAmount);

    //user buy ticker by manager
    function buyTicker(
        address buyer,
        uint256 minerLevel,
        uint256 payAmount,
        uint256 multiple
    ) public onlyManager {
        tickerIndex += 1;
        //receive user money
        payToken.transferFrom(buyer, address(this), payAmount);
        Ticker memory ticker = Ticker(buyer,minerLevel, payAmount,false,multiple);
        userTickMap[buyer][tickerIndex]=ticker;
        emit TickerBuy(buyer,minerLevel, payAmount,tickerIndex);
    }

    // this method only called by manager。 If anyone calle this method is very dangerous
    function rewardTiker(
        address buyer,
        uint256 payAmount
    ) public onlyManager {
        uint rewardAmount = payAmount*(rewardMul-1);
        require(payToken.balanceOf(address(this))>=rewardAmount,"not enough reward");
        //receive user money
        payToken.transferFrom(address(this),buyer, rewardAmount);
        emit RewardTicker(buyer,rewardAmount);
    }

    //destroy the ticker to buy the miner
    function useTicker(address user,uint index)public onlyManager{
        Ticker storage ticker = userTickMap[user][index];
        ticker.isUsed = true;
        emit DestoryTicker(user,index);
    }

    function getUserTick(address user,uint index) public view returns(Ticker memory) {
        return userTickMap[user][index];
    }

    function setManager(address _manager, bool _flag) public onlyOwner {
        isManager[_manager] = _flag;
    }


    function setRewardMultiple(uint _rewardMul) public onlyManager {
        rewardMul = _rewardMul;
    }

    
}
