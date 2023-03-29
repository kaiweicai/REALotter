//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./interfaces/IERC20.sol";
import "./TickerContract.sol";
// import "hardhat/console.sol";

contract MinerContract is OwnableUpgradeable {

        // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    // Declare a set state variable
    EnumerableMap.AddressToUintMap distributionMap;

    function distributionMapSize() public view returns(uint256){
        return distributionMap.length();
    }

    function getDisributeAddresses() public view returns(address[] memory,uint256[] memory){
        address[] memory addresses = new address[](distributionMap.length());
        uint256[] memory percents = new uint256[](distributionMap.length());
        for(uint256 i = 0; i <distributionMap.length(); i++){
            (address dis,uint256 per)=distributionMap.at(i);
            addresses[i] = dis;
            percents[i] = per;
        }
        return (addresses,percents);
    }

    function setDistributionMap(address[] memory distributionAddresses,uint256[] memory distributionPercent) public onlyManager {
        uint256 addressLength = distributionAddresses.length;
        uint256 percentLength = distributionPercent.length;
        require(addressLength==percentLength,"address not eq percent");
        uint256 distributeLength = distributionMap.length();
        for(uint256 j=0;j<distributeLength;j++) {
            (address deliveryAddress,uint256 _percent)=distributionMap.at(0);
            distributionMap.remove(deliveryAddress);
        }
        for(uint256 i = 0; i < addressLength; i++){
            distributionMap.set(distributionAddresses[i],distributionPercent[i]);
        }
    }

    function setIsSendProfit(bool _isSendProfit) public onlyManager {
        isSendProfit = _isSendProfit;
    }

    IERC20 public reaToken; // is REA token to buy the ticker
    IERC20 public usdtToken;
    TickerContract public tickerContract;
    mapping(address => bool) public isManager;
    // address public blackholeAddress;    // blackhole address
    // uint256 public blackHolePercent;    // blackhole percent
    // address public ecologyAddress;
    // uint256 public ecologyPercent;
    // address public teamRewardAddress;
    // uint256 public teamRewardPercent;
    uint public base=10000;   //  base 
    //store the fee token
    // address public claimAccountAddress;
    //store the usdt token
    address public storeUsdtAddress;
    // the profit product account
    address public profitProductAccount;
    mapping(address => mapping(uint256 => Miner)) public userMinerMap;

    // mapping(address => mapping(uint256 => uint)) public userClaimProfileMap;    //user=>miner=>profit amount

    // mapping(uint=>uint) public levelFeeMapping; // level to fee mapping

    bool public isSendProfit = true;

    //onlyManager
    modifier onlyManager() {
        require(isManager[msg.sender], "Not manager");
        _;
    }

    function initialize(
        address _reaToken,
        address _usdtToken,
        address[] memory distributionAddresses,
        uint256[] memory distributionPercent,
        // address _blackholeAddress,
        // uint256 _blackHolePercent,
        // address _ecologyAddress,
        // uint256 _ecologyPercent,
        // address _teamRewardAddress,
        // uint256 _teamRewardPercent,
        // address _claimAccountAddress,
        address _tickerContractAddress,
        address _storeUsdtAddress,
        address _profitProductAccount,
        bool _isSendProfit
    ) public initializer {
        isSendProfit = _isSendProfit;
        reaToken = IERC20(_reaToken);
        usdtToken = IERC20(_usdtToken);

        uint256 addressLength = distributionAddresses.length;
        uint256 percentLength = distributionPercent.length;
        require(addressLength==percentLength,"address not eq percent");
        for(uint256 i = 0; i < addressLength; i++){
            distributionMap.set(distributionAddresses[i],distributionPercent[i]);
        }

        // blackholeAddress = _blackholeAddress;
        // blackHolePercent = _blackHolePercent;
        // ecologyAddress = _ecologyAddress;
        // ecologyPercent = _ecologyPercent;
        // teamRewardAddress = _teamRewardAddress;
        // teamRewardPercent = _teamRewardPercent;
        __Ownable_init();
        isManager[msg.sender] = true;
        // levelFeeMapping[1] = 2; 
        // levelFeeMapping[2] = 4;
        // levelFeeMapping[3] = 6; 
        // levelFeeMapping[4] = 10; 
        // levelFeeMapping[5] = 20; 
        // claimAccountAddress = _claimAccountAddress;
        tickerContract = TickerContract(_tickerContractAddress);
        storeUsdtAddress = _storeUsdtAddress;
        profitProductAccount = _profitProductAccount;
    }


    function claimProfit(address userAddress,uint tickerIndex,uint claimAmount,uint claimFeeAmount)public onlyManager{
        
        Miner storage miner = userMinerMap[userAddress][tickerIndex];
        // check the ticker is exist
        require(miner.user == userAddress, "the user is not the buyer");
        // check the left money to less than the profitAmount
        uint claimRewardAmount = miner.claimRewardAmount;
        uint profitAmount = miner.profitAmount; // Mining reward amount. It is the multiple of the pledged amount * mining machine
        claimRewardAmount += claimAmount;
        miner.claimRewardAmount = claimRewardAmount;
        // not limit the profitAmount
        // require(claimRewardAmount<=profitAmount,"claim amount too high"); 

        //receive the fee
        uint minerLevel = miner.level;
        // uint drawFee = levelFeeMapping[minerLevel]*(10**reaToken.decimals());
        require(claimFeeAmount>0,"fee too low!");
        reaToken.transferFrom(userAddress, address(this), claimFeeAmount);
        for(uint256 i = 0; i < distributionMap.length(); i){
            (address distributeAddress,uint256 percent) = distributionMap.at(i);
            reaToken.transfer(distributeAddress, claimFeeAmount*percent/base);
        }

        if (claimRewardAmount == profitAmount){
            // this miner exit
            miner.isExit = true;
        }
        // Increase the transfer amount of the mining machine and withdraw it to the user. Send withdrawal event
        
        IERC20 profileToken = IERC20(miner.profitToken);
        if(isSendProfit){
            // transfer profit to user
            profileToken.transferFrom(profitProductAccount,userAddress, claimAmount);
        }
        // emit the ClaimPorfit event
        emit ClaimProfit(userAddress,tickerIndex,minerLevel,miner.multiple,claimAmount,claimFeeAmount,miner.profitToken);
    }

    event ClaimProfit(
        address user,
        uint256 minerIndex,
        uint256 level,
        uint256 multiple,
        uint256 claimAmount,
        uint256 feeAmount,
        address profitToken
    );

    

    struct Miner {
        address user;
        uint256 tickerIndex;
        uint256 level;
        uint256 multiple; // the reward multiple
        uint256 profitAmount; //total reward value
        uint256 payAmount; // pay REA amount
        uint256 usdtAmount; // pay usdt amount
        address profitToken; // profit token
        uint claimRewardAmount; // claim reward amount
        bool isExit;             //is exit
    }

    //pledge the miner
    function pledgeMiner(
        address buyer,
        uint256 tickerIndex,
        uint256 payAmount,
        uint256 usdtAmount,
        uint256 profitAmount
    ) public onlyManager {
        //query user have the ticker
        TickerContract.Ticker memory ticker = tickerContract.getUserTick(
            buyer,
            tickerIndex
        );
        // check the ticker is exist
        require(ticker.buyer == buyer, "the user is not the buyer");
        require(ticker.isUsed == false, "ticker is used");
        //notice tickerContract.useTicker method can be called by manager,so must set this contract is the manager of the tickerContract
        tickerContract.useTicker(buyer, tickerIndex);
        //receive user money
        require(payAmount>0,"fee too low!");
        reaToken.transferFrom(buyer, address(this), payAmount);
        for(uint256 i = 0; i < distributionMap.length(); i){
            (address distributeAddress,uint256 percent) = distributionMap.at(i);
            reaToken.transfer(distributeAddress, payAmount*percent/base);
        }
        // reaToken.transfer(blackholeAddress, payAmount*blackHolePercent/base);
        // reaToken.transfer(ecologyAddress, payAmount*ecologyPercent/base);
        // reaToken.transfer(teamRewardAddress, payAmount*teamRewardPercent/base);

        if (usdtAmount > 0) {
            usdtToken.transferFrom(buyer, storeUsdtAddress, usdtAmount);
        }

        // generate the minter
        Miner memory miner = Miner({
            user: buyer,
            tickerIndex: tickerIndex,
            level: ticker.minerLevel,
            multiple: ticker.multiple,
            profitAmount: profitAmount,
            payAmount: payAmount,
            usdtAmount: usdtAmount,
            profitToken:ticker.profitToken,
            claimRewardAmount:0,
            isExit : false
        });

        userMinerMap[buyer][tickerIndex] = miner;

        // emit a pledge event
        emit PledgeMiner(buyer,tickerIndex,ticker.minerLevel,ticker.multiple,profitAmount,payAmount,usdtAmount,ticker.profitToken);
    }


    event PledgeMiner(
        address user,
        uint256 tickerIndex,
        uint256 level,
        uint256 multiple,
        uint256 profitAmount,
        uint256 payAmount,
        uint256 usdtAmount,
        address profitToken
    );

    function setManager(address _manager, bool _flag) public onlyOwner {
        isManager[_manager] = _flag;
    }

    // function setBloackHoleAddress(address _blackholeAddress)
    //     public
    //     onlyManager
    // {
    //     blackholeAddress = _blackholeAddress;
    // }

    // function setEcologyAddress(address _ecologyAddress) public onlyManager {
    //     ecologyAddress = _ecologyAddress;
    // }

    // function setTeamRewardAddress(address _teamRewardAddress)
    //     public
    //     onlyManager
    // {
    //     teamRewardAddress = _teamRewardAddress;
    // }

    // function setBlackHolePercent(uint256 _blackHolePercent) public onlyManager {
    //     blackHolePercent = _blackHolePercent;
    // }

    // function setEcologyPercent(uint256 _ecologyPercent) public onlyManager {
    //     ecologyPercent = _ecologyPercent;
    // }

    // function setLevelFee(uint level,uint fee) public onlyManager {
    //     levelFeeMapping[level]=fee;
    // }

    // function setTeamRewardPercent(uint256 _teamRewardPercent)
    //     public
    //     onlyManager
    // {
    //     teamRewardPercent = _teamRewardPercent;
    // }

    // function setClaimAccountAddress(address _claimAccountAddress) public onlyManager {
    //     claimAccountAddress = _claimAccountAddress;
    // }

    function setStoreUsdtAddress(address _storeUsdtAddress) public onlyManager {
        storeUsdtAddress = _storeUsdtAddress;
    }

    function setProfitProductAccount(address _profitProductAccount) public onlyManager {
        profitProductAccount = _profitProductAccount;
    }

    function setTickerContract(address _tickerContract) public onlyManager {
        tickerContract = TickerContract(_tickerContract);
    }
}
