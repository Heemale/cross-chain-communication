import hre, { ethers } from 'hardhat';
// import hre from "hardhat";

// import { ethers } from "hardhat";

function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}


async function main() {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }

  const [owner] = accounts;

  const routerAddress = '0x907585c9acEB796BB1b349e86F2Bc27fAA4E180c';

  const tokenA = await ethers.getContractAt('Token', '0x5B8A8EE4aD4144D668E1cF1e93cA041324e3810B');
  const tokenB = await ethers.getContractAt('Token', '0x0b9Bd388609FB01a0ef3234Ad8297DdC0Bf5d2AE');
  const test = await ethers.getContractAt('Test', '0x5FbDB2315678afecb367f032d93F642f64180aa3');

  const balance1 = await tokenA.balanceOf(owner.address);
  const balance2 = await tokenB.balanceOf(owner.address);
  console.log({ balance1 });
  console.log({ balance2 });

  const res1 = await tokenA.connect(owner).approve(routerAddress, ethers.parseEther('1'));
  console.log({ res1 });
  await delay(2000);

  const allowance = await tokenA.allowance(owner.address, routerAddress);
  console.log({ allowance });

  const res2 = await test.connect(owner).onCrossChainCall(
    ethers.getBytes('0x0000000000000000000000005b8a8ee4ad4144d668e1cf1e93ca041324e3810b0000000000000000000000000b9bd388609fb01a0ef3234ad8297ddc0bf5d2ae0000000000000000000000000000000000000000000000000000000005f5e100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008bfce642119e30ebc9ef6ec1a5c4c20b009361200000000000000000000000000000000000000000000000000000000675a629c'),
  );
  console.log({ res2 });
  // await tx.wait(); // 等待交易确认
  // console.log("Transaction completed:", tx);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
