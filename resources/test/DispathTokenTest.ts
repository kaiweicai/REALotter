import { expect, use } from "chai";
import { MockProvider } from "ethereum-waffle";
import { BigNumber, BigNumberish, Contract, Wallet } from "ethers";
import { ethers, upgrades, waffle } from "hardhat";
// import { ITokenAFeeHandler, IBananaSwapPair, TokenManager } from "../types";
import { AddressZero, MaxUint256, Zero } from "@ethersproject/constants";
const blackHoleAddress = "000000000000000000000000000000000000dEaD";
const overrides = {
    gasLimit: 9999999,
};
import { expandTo18Decimals, MINIMUM_LIQUIDITY, setNextBlockTime, encodePrice } from "./shared/utilities";
import exp from "constants";

describe("DispatchToken contract init and test", () => {
    const loadFixture = waffle.createFixtureLoader(waffle.provider.getWallets(), waffle.provider);

    async function v2Fixture(
        [wallet, user, address1, address2, address3, address4, address5, address6, address7, address8, address9, address10]: Wallet[],
        provider: MockProvider
    ) {
        const DispatchTokenContract = await ethers.getContractFactory("DispatchToken");
        const dispatchTokenContract = await DispatchTokenContract.deploy();
        const SmartERC20 = await ethers.getContractFactory("SmartERC20");
        const usdt = await SmartERC20.deploy();
        await usdt.initialize("usdt token", "USDT");
        usdt.connect(address1).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address1.address});
        usdt.connect(address2).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address2.address});
        usdt.connect(address3).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address3.address});
        usdt.connect(address4).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address4.address});
        usdt.connect(address5).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address5.address});
        usdt.connect(address6).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address6.address});
        usdt.connect(address7).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address7.address});
        usdt.connect(address8).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address8.address});
        usdt.connect(address9).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address9.address});
        usdt.connect(address10).approve(dispatchTokenContract.address,10000000000000000000000000000n,{from:address10.address});
        console.log("init DispatchToken!");

        return {
            dispatchTokenContract,
            usdt,
            wallet,
            user,
            address1,
            address2,
            address3,
            address4,
            address5,
            address6,
            address7,
            address8,
            address9,
            address10,
        };
    }

    describe("deploy dispatch test", () => {
        it("test dispatch token init", async () => {
            const {
                dispatchTokenContract,
                usdt,
                wallet,
                user,
                address1,
                address2,
                address3,
                address4,
                address5,
                address6,
                address7,
                address8,
                address9,
                address10,
            } = await loadFixture(v2Fixture);
            let dispatchAddressArray: string[] = [];

            dispatchAddressArray.push(address1.address);
            dispatchAddressArray.push(address2.address);
            dispatchAddressArray.push(address3.address);
            dispatchAddressArray.push(address4.address);
            dispatchAddressArray.push(address5.address);
            dispatchAddressArray.push(address6.address);
            dispatchAddressArray.push(address7.address);
            dispatchAddressArray.push(address8.address);
            dispatchAddressArray.push(address9.address);
            dispatchAddressArray.push(address10.address);

            // let random = await dispatchTokenContract.randomNumber(1);
            // console.log("random")
			

            await dispatchTokenContract.initialize(dispatchAddressArray, usdt.address, wallet.address);
            let usdtToken = await dispatchTokenContract.usdtToken();
			expect(usdtToken).to.be.equal(usdt.address);
            console.log("usdt token address:",usdtToken);
			let collectionAddress = await dispatchTokenContract.collectionAddr();
			expect(collectionAddress).to.be.equal(wallet.address);
            let owner = await dispatchTokenContract.owner();
            console.log("owner is:",owner);
            console.log("wallet.address is:",wallet.address);

            await dispatchTokenContract.setDispatchAddresses(dispatchAddressArray);
            let dispatchAddresses = await dispatchTokenContract.getDispatchAddressSet();
			// console.log("dispatchAddressArray is:",dispatchAddressArray);
            // console.log("dispatchAddresses is:", dispatchAddresses);
			for(let j=0;j<10;j++){
				// let indexOf = dispatchAddresses.indexOf(dispatchAddressArray[j]);
				// console.log("indexOf :",indexOf);
				expect(dispatchAddresses.indexOf(dispatchAddressArray[j])).to.be.greaterThan(-1);
			}
			
        });
    });

    describe.only("dispatch token test", () => {
        it("test dispatch token", async () => {
            const {
                dispatchTokenContract,
                usdt,
                wallet, //collectionWallet,owner
                user,// user dispatch
                address1,
                address2,
                address3,
                address4,
                address5,
                address6,
                address7,
                address8,
                address9,
                address10,
            } = await loadFixture(v2Fixture);
            let dispatchAddressArray: string[] = [];

            dispatchAddressArray.push(address1.address);
            dispatchAddressArray.push(address2.address);
            dispatchAddressArray.push(address3.address);
            dispatchAddressArray.push(address4.address);
            dispatchAddressArray.push(address5.address);
            dispatchAddressArray.push(address6.address);
            dispatchAddressArray.push(address7.address);
            dispatchAddressArray.push(address8.address);
            dispatchAddressArray.push(address9.address);
            dispatchAddressArray.push(address10.address);

            await dispatchTokenContract.initialize(dispatchAddressArray, usdt.address, wallet.address);

			// start dispatch token
            let usdtDecimal = await usdt.decimals();
            console.log("usdt decimal is:",usdtDecimal);
            

            let dispatchTokenAmount = 10000000000000000000000n
            await usdt.mint(user.address,dispatchTokenAmount);
            expect(await usdt.balanceOf(user.address)).to.be.equal(dispatchTokenAmount);

            await usdt.connect(user).approve(dispatchTokenContract.address,dispatchTokenAmount);

            let dispatchAmount = 1000000000000000000000n;
            let dispatchAmountArray = [];
            dispatchAmountArray.push(dispatchAmount);
            dispatchAmountArray.push(dispatchAmount);
            dispatchAmountArray.push(dispatchAmount);
            dispatchAmountArray.push(dispatchAmount);
            dispatchAmountArray.push(dispatchAmount);
            dispatchAmountArray.push(dispatchAmount);
            dispatchAmountArray.push(dispatchAmount);
            dispatchAmountArray.push(dispatchAmount);
            await expect(dispatchTokenContract.dispatch1(user.address,dispatchAmountArray)).to.be.revertedWith("dispatch length not match");
            dispatchAmountArray.push(dispatchAmount);
            
            dispatchAmountArray.push(dispatchAmount);

            let tradeDispatchAddressArray: string[] = [];

            tradeDispatchAddressArray.push(address10.address);
            tradeDispatchAddressArray.push(address9.address);
            tradeDispatchAddressArray.push(address8.address);
            tradeDispatchAddressArray.push(address7.address);
            tradeDispatchAddressArray.push(address6.address);
            tradeDispatchAddressArray.push(address5.address);
            tradeDispatchAddressArray.push(address4.address);
            tradeDispatchAddressArray.push(address3.address);
            tradeDispatchAddressArray.push(address2.address);
            tradeDispatchAddressArray.push(address1.address);

            let tradeDispatchAmountArray = [];
            tradeDispatchAmountArray.push(100n);
            tradeDispatchAmountArray.push(200n);
            tradeDispatchAmountArray.push(300n);
            tradeDispatchAmountArray.push(400n);
            tradeDispatchAmountArray.push(500n);
            tradeDispatchAmountArray.push(600n);
            tradeDispatchAmountArray.push(700n);
            tradeDispatchAmountArray.push(800n);
            tradeDispatchAmountArray.push(900n);
            tradeDispatchAmountArray.push(100n);

            // 检查状态,未开始前不可交易
            await expect(dispatchTokenContract.trade2(tradeDispatchAddressArray,tradeDispatchAmountArray)).to.be.revertedWith("step2 state wrong");
            // 检查是否是管理员
            await expect(dispatchTokenContract.connect(user).dispatch1(user.address,dispatchAmountArray,{from:user.address})).to.be.revertedWith("Not manager");
            //开始分派
			await dispatchTokenContract.dispatch1(user.address,dispatchAmountArray);
            // expect the 
            let afterDispatchUserBalance = await usdt.balanceOf(user.address);
            expect(afterDispatchUserBalance).to.be.equal(0);
            console.log("afterDispatchUserBalance is:",afterDispatchUserBalance);

            let dispatchAddresses = await dispatchTokenContract.getDispatchAddressSet();
            for(let i=0;i<dispatchAddresses.length;i++){
                let balanceOf = await usdt.balanceOf(dispatchAddresses[i]);
                expect(balanceOf).to.be.equal(dispatchAmount);
            }

            // 状态检查,非初始化状态
            await expect(dispatchTokenContract.dispatch1(user.address,dispatchAmountArray)).to.be.revertedWith("other dispatch is run");


            
            await dispatchTokenContract.trade2(tradeDispatchAddressArray,tradeDispatchAmountArray);

            for(let i=0;i<dispatchAddresses.length;i++){
                let balanceOf = await usdt.balanceOf(dispatchAddresses[i]);
                console.log("balanceOf is:",balanceOf);
                // expect(balanceOf).to.be.equal(dispatchAmount);
            }

            console.log("----------------------------------------------");

            await dispatchTokenContract.trade2(tradeDispatchAddressArray,tradeDispatchAmountArray);

            for(let i=0;i<dispatchAddresses.length;i++){
                let balanceOf = await usdt.balanceOf(dispatchAddresses[i]);
                console.log("balanceOf is:",balanceOf);
                // expect(balanceOf).to.be.equal(dispatchAmount);
            }

            // 开始归集
            let beforeCollectBalance = await usdt.balanceOf(wallet.address);
            expect(beforeCollectBalance).to.be.equal(0);
            await dispatchTokenContract.collectAll();
            let afterCollectBalance = await usdt.balanceOf(wallet.address);
            expect(afterCollectBalance).to.be.equal(dispatchTokenAmount);

        });
    });
});
