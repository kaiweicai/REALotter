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


            let dispatchAmountArray = [];
            dispatchAmountArray.push(1000000000000000000000n);
            dispatchAmountArray.push(1000000000000000000000n);
            dispatchAmountArray.push(1000000000000000000000n);
            dispatchAmountArray.push(1000000000000000000000n);
            dispatchAmountArray.push(1000000000000000000000n);
            dispatchAmountArray.push(1000000000000000000000n);
            dispatchAmountArray.push(1000000000000000000000n);
            dispatchAmountArray.push(1000000000000000000000n);
            await expect(dispatchTokenContract.dispatch1(user.address,dispatchAmountArray)).to.be.revertedWith("dispatch length not match");
            dispatchAmountArray.push(1000000000000000000000n);
            
            dispatchAmountArray.push(1000000000000000000000n);

            await expect(dispatchTokenContract.connect(user).dispatch1(user.address,dispatchAmountArray,{from:user.address})).to.be.revertedWith("Not manager");

			await dispatchTokenContract.dispatch1(user.address,dispatchAmountArray);
            // expect the 
            let afterDispatchUserBalance =usdt.balanceOf(user.address);
            console.log("afterDispatchUserBalance is:",afterDispatchUserBalance);
        });
    });
});
