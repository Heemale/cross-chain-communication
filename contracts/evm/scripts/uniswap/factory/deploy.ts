import hre, { ethers } from 'hardhat';

async function main() {
  const accounts = await hre.ethers.getSigners();

  const [owner] = accounts;

  const factory = await ethers.getContractFactory('UniswapV2Factory');

  const instance = await factory.connect(owner).deploy(owner.address);

  console.log({ instance });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});