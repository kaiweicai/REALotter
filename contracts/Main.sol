// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Main is OwnableUpgradeable{
    //deploy fee 1 eth
    uint deploy_fee = 1 ether/10;
    // price for batch Mint per page
    uint batch_mint_fee = 5 ether / 10000;

    mapping (bytes32=>mapping(bytes32=>Token)) tokenMap;

    event Withdrawal(uint amount, uint when);
    event Deploy(address indexed user,bytes32 protocol,bytes32 tick,uint supply,uint limit);
    event Mint(address indexed  user,bytes32 protocol,bytes32 tick,uint batch_page);

    mapping(address => bool) public isManager;

    //onlyManager
    modifier onlyManager() {
        require(isManager[msg.sender], "Not manager");
        _;
    }

    struct Token{
        bytes32 protocal;
        bytes32 tick;
        uint maxSupply;
        uint pageLimit;
        uint page;
    }

    constructor() payable {
    }

    function initialize() public initializer {

        __Ownable_init();
        isManager[msg.sender] = true;
    }



    //protocal: protocal name
    //tick: ticker name
    function deploy(bytes32 protocal,bytes32 tick,uint maxSupply,uint pageLimit) public payable{
        //check the protocal and tick is exist
        require(tokenMap[protocal][tick].maxSupply != 0,"ticker has exist");
        require(maxSupply >= pageLimit,"supply less than pageLimit");
        Token memory token = Token(
            protocal,tick,maxSupply,pageLimit,maxSupply/pageLimit
        );
        tokenMap[protocal][tick] = token;

        uint pay_amount = msg.value;
        require(pay_amount == deploy_fee,"payment not correct");
        
        uint init_page = pay_amount / batch_mint_fee;
        emit Deploy(msg.sender,protocal,tick,maxSupply,pageLimit);
        emit Mint(msg.sender,protocal,tick,init_page);
    }

    function mint(bytes32 protocal,bytes32 tick,uint batch_page) public payable{
        require(tokenMap[protocal][tick].maxSupply != 0,"ticker not exist");
        uint pay_amount = msg.value;
        uint page = pay_amount / batch_mint_fee;
        require(page >= batch_page ,"payment not enough");
        emit Mint(msg.sender,protocal,tick,page);
    }

    //Query the required funds for batch issuance
    function queryBatchMintPayable(uint batch_page)public view returns (uint mintPayable){
        return batch_page * batch_mint_fee;
    }
    

    //owner whthdraw draw eth
    function withdraw() public onlyManager{
        address payable owner = payable(owner());
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}
