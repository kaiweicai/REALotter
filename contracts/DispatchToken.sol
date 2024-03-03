// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IERC20.sol";
// Uncomment this line to use console.log
import "hardhat/console.sol";

contract DispatchToken is OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    //100个地址
    EnumerableSet.AddressSet dispatchAddressSet;

    IERC20 public usdtToken;

    address public collectionAddr;

    uint public state; //当前合约状态,0:初始化状态,1:第一步dispatch完成,把用户的资金分发到各个分派账户,2:第二步,各个分派账户相互转账.3.第三步完成,归集完成

    mapping(address => bool) public isManager;

    //onlyManager
    modifier onlyManager() {
        require(isManager[msg.sender], "Not manager");
        _;
    }

    constructor() {}

    //初始化,参数:分发地址,设置需要处理的USDT合约地址地址,最后的收集地址
    function initialize(address[] memory _dispatchAddresses, address _usdtAddress, address _collectionAddr) public initializer {
        __Ownable_init();
        isManager[msg.sender] = true;
        usdtToken = IERC20(_usdtAddress);
        collectionAddr = _collectionAddr;
        for (uint j = 0; j < _dispatchAddresses.length; j++) {
            dispatchAddressSet.add(_dispatchAddresses[j]);
        }
    }

    //开始第一步分发,参数:dispatchAddress:分发地址,dispatchAmount:分发数量
    function dispatch1(address dispatchAddress,uint dispatchAmount) public onlyManager {
        uint[] memory dispatchAmountArray = randomNumber();
        //状态检查,非初始化状态或者已经完成状态,不可以开始分派.
        require(state == 0 || state == 3, "other dispatch is run");
        state = 1;
        require(dispatchAddressSet.length() == dispatchAmountArray.length, "dispatch length not match");
        uint length = dispatchAddressSet.length();
        uint averageDispatchAmount = dispatchAmount/length;
        for (uint i = 0; i < dispatchAmountArray.length; i++) {
            if(i%2==0){
                usdtToken.transferFrom(dispatchAddress, dispatchAddressSet.at(i), averageDispatchAmount*dispatchAmountArray[i]/100);
            }else{
                usdtToken.transferFrom(dispatchAddress, dispatchAddressSet.at(i), averageDispatchAmount + (averageDispatchAmount*(100-dispatchAmountArray[i-1])/100));
            }
            
        }
    }

    //开始第二步转账
    function trade2() public onlyManager {
        (uint[] memory tradeAddresses, uint[] memory dispatchAmountArray) = randomAddress();
        require(state == 1 || state == 2, "step2 state wrong");
        state = 2;
        require(tradeAddresses.length == dispatchAmountArray.length, "length not match");
        for (uint i = 0; i < tradeAddresses.length; i++) {
            address fromAddress = dispatchAddressSet.at(tradeAddresses[i]);
            uint transferBalance = usdtToken.balanceOf(fromAddress)*dispatchAmountArray[i]/100;
            usdtToken.transferFrom(fromAddress, dispatchAddressSet.at(i), transferBalance);
        }
    }

    // //第三步,归集资金.参数:
    // function collecte3(address[] memory tradeAddresses,uint[] memory dispatchAmountArray)public onlyManager{
    //     require(tradeAddresses.length == dispatchAmountArray.length,"3 length not match");
    //     for(uint i=0;i<tradeAddresses.length;i++){
    //         usdtToken.transferFrom(tradeAddresses[i],collectionAddr,dispatchAmountArray[i]);
    //     }
    // }

    //第三步,归集所有的资金,只有合约所有者能够操作
    function collectAll() public onlyManager {
        require(state == 2, "step3 state wrong");
        state = 3;
        address[] memory dispathAddresses = dispatchAddressSet.values();
        for (uint i = 0; i < dispathAddresses.length; i++) {
            uint balance = usdtToken.balanceOf(dispathAddresses[i]);
            usdtToken.transferFrom(dispathAddresses[i], collectionAddr, balance);
        }
    }

    //设置中转地址,清空原有的分发者地址,设置新的合约所有者设置分发地址.参数:中转地址数组
    function setDispatchAddresses(address[] memory _dispatchAddresses) public onlyOwner {
        console.log("set address start");
        address[] memory addrArray = dispatchAddressSet.values();
        if (addrArray.length > 0) {
            for (uint i = 0; i < addrArray.length; i++) {
                dispatchAddressSet.remove(addrArray[i]);
            }
        }

        console.log(_dispatchAddresses[0]);

        for (uint j = 0; j < _dispatchAddresses.length; j++) {
            dispatchAddressSet.add(_dispatchAddresses[j]);
        }
        console.log("set address end");
    }

    function getDispatchAddressSet() public view returns (address[] memory) {
        return dispatchAddressSet.values();
    }

    //设置处理TOKNE address
    function setTokenAddress(address _usdtAddress) public onlyOwner {
        usdtToken = IERC20(_usdtAddress);
    }

    //设置归集地址
    function setCollectionAddress(address _collectionAddr) public onlyOwner {
        collectionAddr = _collectionAddr;
    }

    function setManager(address _manager, bool _flag) public onlyOwner {
        isManager[_manager] = _flag;
    }

    function randomNumber() public view returns (uint[] memory) {
        uint randomNow = uint(keccak256(abi.encode(block.timestamp, block.number, block.difficulty, msg.sender)));
        uint randomNum = uint(keccak256(abi.encode(randomNow, block.number)));
        console.log("randomNum is:", randomNum);
        console.log("dispatchAddressSet.length()",dispatchAddressSet.length());
        uint dispatchSetLen = dispatchAddressSet.length();
        uint[] memory result = new uint[](dispatchSetLen);
        for (uint i = 0; i < dispatchSetLen; i++) {
            result[i] = randomNum % 100;
            console.log("result[i] is:", result[i]);
            randomNum = randomNum / 3;
        }
        return result;
    }

    function randomAddress() public view returns (uint[] memory,uint[] memory) {
        uint[] memory randomNumbers = randomNumber();
        uint length = dispatchAddressSet.length();
        uint[] memory result = new uint[](length);
        uint[] memory temp = new uint[](length);
        
        uint k = 0;
        for (uint i = 0; i < length; i++) {
            if (result[randomNumbers[i]%length] == 0) {
                result[randomNumbers[i]%length] = i;
            } else {
                temp[k] = i;
                k = k + 1;
            }
        }
        uint n = 0;
        for (uint j = 0; j < length; j++) {
            if (result[j] == 0) {
                result[j] = temp[n];
                n = n+1;
            }
        }
        return (result,randomNumbers);
    }
}
