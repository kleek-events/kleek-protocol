const { ethers, upgrades } = require("hardhat");
const { AbiCoder } = require("ethers");

const USDC_ADDRESS = 0x036cbd53842c5426634e7929541ec2318f3dcf7e;

async function main() {
  const kleek = await ethers.getContractAt(
    "Kleek",
    "0xfC445c7ceBc111D2AB612F50c69f1c625Ef98286"
  );

  //   add to whitelist
  //   await kleek.whitelistConditionModule(
  //     "0x9C51aC10146A4C3Fe0D19ec7071371b1CA58c2e7",
  //     true
  //   );

  const depositFee = BigInt(0.01 * 10 ** 6);
  const params = AbiCoder.defaultAbiCoder().encode(
    [{ type: "uint256" }, { type: "address" }],
    [depositFee, "0x036cbd53842c5426634e7929541ec2318f3dcf7e"]
  );

  console.log(params);
  const tx = await kleek.create(
    "http://ipfs",
    1726514740,
    1726514730,
    10,
    "0x9C51aC10146A4C3Fe0D19ec7071371b1CA58c2e7",
    params
  );
  await tx.wait();
}

main();
