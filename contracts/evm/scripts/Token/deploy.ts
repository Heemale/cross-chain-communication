import hre, { ethers } from 'hardhat';

async function main() {
  const accounts = await hre.ethers.getSigners();

  const [owner] = accounts;

  const factory = await ethers.getContractFactory('Token');

  const instance = await factory.connect(owner).deploy(
    ethers.parseEther('500000'),
    'A',
    'A',
  );

  console.log({ instance});
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});