import { MockProvider } from "@ethereum-waffle/provider";
import { BigNumber, Contract } from "ethers";
import { utils as ethutil } from "ethers";

const { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack } = ethutil;

const PERMIT_TYPEHASH = keccak256(
  toUtf8Bytes(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  )
);

export function expandTo18Decimals(n: number): BigNumber {
  return BigNumber.from(n).mul(BigNumber.from(10).pow(18));
}

export function expandTo8Decimals(n: number): BigNumber {
  return BigNumber.from(n).mul(BigNumber.from(10).pow(8));
}

function getDomainSeparator(name: string, tokenAddress: string) {
  return keccak256(
    defaultAbiCoder.encode(
      ["bytes32", "bytes32", "bytes32", "uint256", "address"],
      [
        keccak256(
          toUtf8Bytes(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          )
        ),
        keccak256(toUtf8Bytes(name)),
        keccak256(toUtf8Bytes("1")),
        1,
        tokenAddress,
      ]
    )
  );
}

export function getCreate2Address(
  factoryAddress: string,
  [tokenA, tokenB]: [string, string],
  bytecode: string
): string {
  const [token0, token1] =
    tokenA < tokenB ? [tokenA, tokenB] : [tokenB, tokenA];
  return ethutil.getCreate2Address(
    factoryAddress,
    keccak256(solidityPack(["address", "address"], [token0, token1])),
    keccak256(bytecode)
  );
}


export function encodePrice(reserve0: BigNumber, reserve1: BigNumber) {
  return [
    reserve1.mul(BigNumber.from(2).pow(112)).div(reserve0),
    reserve0.mul(BigNumber.from(2).pow(112)).div(reserve1),
  ];
}

export async function setNextBlockTime(
  provider: MockProvider,
  timestamp: number
): Promise<void> {
  return provider.send("evm_setNextBlockTimestamp", [timestamp]);
}

export function tokenAIsToken0(
  tokenA:string,
  tokenB:string,
): Boolean {
  return tokenA.toUpperCase() < tokenB.toUpperCase();
}

export const MINIMUM_LIQUIDITY = BigNumber.from(10).pow(3);
