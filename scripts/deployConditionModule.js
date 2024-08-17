const { ethers } = require("hardhat");

async function main() {
  const ShareDeposit = await ethers.getContractFactory("ShareDeposit");
  const shareDeposit = await ShareDeposit.deploy(
    "0xfC445c7ceBc111D2AB612F50c69f1c625Ef98286"
  );
  await shareDeposit.waitForDeployment();
  console.log("ShareDeposit deployed to:", await shareDeposit.getAddress());
}

main();
