import { expect, use } from "chai";
import { MockProvider } from "ethereum-waffle";
import { BigNumber, BigNumberish, Contract, Wallet } from "ethers";
import { ethers, upgrades, waffle } from "hardhat";
// import { ITokenAFeeHandler, IBananaSwapPair, TokenManager } from "../types";
import { AddressZero, MaxUint256, Zero } from '@ethersproject/constants';
const blackHoleAddress = "000000000000000000000000000000000000dEaD";
const overrides = {
	gasLimit: 9999999
}
import {
	expandTo18Decimals,
	MINIMUM_LIQUIDITY,
	setNextBlockTime,
	encodePrice,
} from "./shared/utilities";
import exp from "constants";

describe("DispatchToken contract init and test", () => {
	const loadFixture = waffle.createFixtureLoader(
		waffle.provider.getWallets(),
		waffle.provider
	);

	async function v2Fixture([wallet, user,address1,address4,address5,address6]: Wallet[], provider: MockProvider) {
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
			address4,
			address5,
			address6,
		};
	}

	describe.only("deploy dispatch test", () => {
		it("test dispatch token init", async () => {
			const {
				dispatchTokenContract,
				usdt,
				wallet,
				user,
				address1,
				address4,
				address5,
				address6,
			} = await loadFixture(
				v2Fixture
			);
			await dispatchTokenContract.initialize(usdt.address,address6.address);
			let usdtToken = await dispatchTokenContract.usdtToken();
			console.log(usdtToken);
			let i =600;
			let dispatchAddress:string[] = [];
			for (let j=0;j<i;j++){
				dispatchAddress.push(address5.address);
			}
			console.log("dispatchAddress is:",dispatchAddress);
			await dispatchTokenContract.setDispatchAddresses(dispatchAddress);
			let dispatchAddresses =  await dispatchTokenContract.getDispatchAddressSet();
			console.log("dispatchAddresses is:{}",dispatchAddresses);
		});


	});

});