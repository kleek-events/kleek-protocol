const { ethers, upgrades } = require("hardhat");

async function main() {
  const Kleek = await ethers.getContractFactory("Kleek");
  const kleek = await upgrades.deployProxy(Kleek, [
    "0xfC445c7ceBc111D2AB612F50c69f1c625Ef98286", // Kleek contract is the owner
  ]);
  await kleek.waitForDeployment();
  console.log("ShareDeposit deployed to:", await kleek.getAddress());
}

main();
