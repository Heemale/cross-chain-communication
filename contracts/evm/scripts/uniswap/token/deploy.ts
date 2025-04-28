import hre, { ethers } from 'hardhat';

async function main() {
  const accounts = await hre.ethers.getSigners();

  const [owner] = accounts;

  const factory = await ethers.getContractFactory('Token');

  const instance1 = await factory.connect(owner).deploy(
    ethers.parseEther('500000'),
    'A',
    'A',
  );

  const instance2 = await factory.connect(owner).deploy(
    ethers.parseEther('500000'),
    'B',
    'B',
  );

  const instance3 = await factory.connect(owner).deploy(
    ethers.parseEther('500000'),
    'WETH',
    'WETH',
  );

  console.log({ instance1, instance2, instance3 });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});