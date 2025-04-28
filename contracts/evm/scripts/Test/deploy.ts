import hre, {ethers} from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();

  const [owner] = accounts;

  const factory = await ethers.getContractFactory("Test");

  const instance = await factory.connect(owner).deploy
    (
      "0x6866B4923fc3Fe89ac10b3eF0aB7e9eF5fC00dCA",
      "0x907585c9acEB796BB1b349e86F2Bc27fAA4E180c",
    );

  console.log({ instance });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});