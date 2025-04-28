import { ethers, upgrades } from 'hardhat';

async function main() {

  const factory = await ethers.getContractFactory("SystemContract",{
    libraries: {
      Message: "0x89608981cA0464596107Fa91C3e9FaBfdAb19c96"
    }
  });

  const systemContract = await upgrades.deployProxy(factory, [], { initializer: "initialize" });

  const instance = await systemContract.deployed();

  console.log({ instance });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});