// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


//


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IERC20.sol";
// Uncomment this line to use console.log
import "hardhat/console.sol";

contract DispatchToken is OwnableUpgradeable{

    using EnumerableSet for EnumerableSet.AddressSet;

    //100个地址
    EnumerableSet.AddressSet dispatchAddressSet;

    IERC20 public usdtToken; 

    address public collectionAddr;

    mapping(address => bool) public isManager;

    //onlyManager
    modifier onlyManager() {
        require(isManager[msg.sender], "Not manager");
        _;
    }


    constructor(){
    }

    //初始化,设置需要处理的USDT地址
    function initialize(address _usdtAddress,address _collectionAddr) public initializer {
        __Ownable_init();
        isManager[msg.sender] = true;
        usdtToken = IERC20(_usdtAddress);
        collectionAddr=_collectionAddr;
    }
    
    //开始第一步分发,处理的账户和处理的金额,传输的数值
    function dispath(address dispathAddress,uint[] memory dispathAmountArray)public onlyManager{
        require(dispatchAddressSet.length()==dispathAmountArray.length,"dispath length not match");
        for(uint i=0;i<dispathAmountArray.length;i++){
            usdtToken.transferFrom(dispathAddress,dispatchAddressSet.at(i),dispathAmountArray[i]);
        }
    }

    //开始第二次转账,100个地址转到另外100个地址.
    function trade2(address[] memory tradeAddresses,uint[] memory dispathAmountArray) public onlyManager{
        require(tradeAddresses.length == dispathAmountArray.length,"length not match");
        for(uint i=0;i<tradeAddresses.length;i++){
            usdtToken.transferFrom(tradeAddresses[i],dispatchAddressSet.at(i),dispathAmountArray[i]);
        }
    }

    //第三步,归集资金
    function collecte3(address[] memory tradeAddresses,uint[] memory dispathAmountArray)public onlyManager{
        require(tradeAddresses.length == dispathAmountArray.length,"3 length not match");
        for(uint i=0;i<tradeAddresses.length;i++){
            usdtToken.transferFrom(tradeAddresses[i],collectionAddr,dispathAmountArray[i]);
        }
    }

    // 归集所有的资金,只有合约所有者能够操作
    function collecteAll()public onlyOwner{
        address[] memory dispathAddresses = dispatchAddressSet.values();
        for(uint i=0;i<dispathAddresses.length;i++){
            uint balance = usdtToken.balanceOf(dispathAddresses[i]);
            usdtToken.transferFrom(dispathAddresses[i],collectionAddr,balance);
        }
    }



    //设置中转地址
    function setDispatchAddresses(address[] memory _dispatchAddresses) public onlyOwner{
        console.log("set address start");
       address[] memory addrArray =  dispatchAddressSet.values();
       if(addrArray.length>0){
        for(uint i=0;i<addrArray.length;i++){
            dispatchAddressSet.remove(addrArray[i]);
        }
       }

       console.log(_dispatchAddresses[0]);
       
       for(uint j=0;j<_dispatchAddresses.length;j++){
        dispatchAddressSet.add(_dispatchAddresses[j]);
       }
       console.log("set address end");
    }

    function getDispatchAddressSet()public view returns (address[] memory){
        return dispatchAddressSet.values();
    }

    //设置处理TOKNE address
    function setTokenAddress(address _usdtAddress) public onlyOwner{
       usdtToken = IERC20(_usdtAddress);
    }

    //设置归集地址
    function setCollectionAddress(address _collectionAddr) public onlyOwner{
       collectionAddr=_collectionAddr;
    }

    function setManager(address _manager, bool _flag) public onlyOwner {
        isManager[_manager] = _flag;
    }
}
