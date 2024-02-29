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

describe("Main contract init and test", () => {
	const loadFixture = waffle.createFixtureLoader(
		waffle.provider.getWallets(),
		waffle.provider
	);

	async function v2Fixture([wallet, user,address1,address4,address5,address6]: Wallet[], provider: MockProvider) {
		const MainContract = await ethers.getContractFactory("Main");
		const mainContract = await MainContract.deploy();
		
		console.log("init main token!");
		
		return {
			mainContract,
			wallet,
			user,
			address1,
			address4,
			address5,
			address6,
		};
	}

	describe.only("deploy main test", () => {

		it("buy ticker by REA", async () => {
			const {
				mainContract,
				wallet,
				user,
				address1,
				address4,
				address5,
				address6,
			} = await loadFixture(
				v2Fixture
			);
			mainContract.deploy("protocol","ERC20",1000,10);
		});


	});

});