// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { expect } = require("chai");

const proxyAdminAddrs = {
  "polygon": "0xe7e22ad06493b97dd86875c7f59f0d71c664c75e"
}

const idnftproxy = {
  "polygon": "0x7a02492bAa66B0b8266a6d25Bbd6D8BA169296CC"
}

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("owner " + owner.address);
  let proxyAdmin = await ethers.getContractAt("ProxyAdmin", proxyAdminAddrs[hre.network.name]);
  console.log("proxyAdmin " + proxyAdmin.address);

  console.log("\ndeploy idnft");
  let IDNFT_Logic = await ethers.getContractFactory("IDCard_V2");
  let idnft_logic = await IDNFT_Logic.deploy();
  await idnft_logic.deployed();
  console.log("idnft logic " + idnft_logic.address);

  let tx = await proxyAdmin.upgrade(idnftproxy[hre.network.name], idnft_logic.address);
  await tx.wait();

  let idnft = await ethers.getContractAt("IDCard_V2", idnftproxy[hre.network.name].address);
  await idnft.initV2();

  console.log("\ndeploy controller");
  let Controller_Logic = await ethers.getContractFactory("IDCard_V2_Controller");
  let controller_logic = await Controller_Logic.deploy();
  console.log("controller logic " + controller_logic.address);

  let i_init = new ethers.utils.Interface(["function initialize()"]);
  let controllerinitdata = i_init.encodeFunctionData("initialize");
  let controller_proxy = await Proxy.deploy(controller_logic.address, proxyAdmin.address, controllerinitdata);
  const Proxy = await ethers.getContractFactory("contracts/proxy/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy");
  await controller_proxy.deployed();
  console.log("controller proxy " + controller_proxy.address);

  let controller = await ethers.getContractAt("IDCard_V2_Controller", controller_proxy.address);
  console.log("controller address " + controller.address);

  // TODO grant idnft controller role
  // TODO init idnft

  console.log("\ngrant controller admin role");
  let role_admin = await controller.DEFAULT_ADMIN_ROLE();
  expect(await controller.hasRole(role_admin, owner.address)).to.equal(true);

  console.log("\ndeploy SBT");
  let MultiHonor_Multichain = "contracts/SBT/" + hre.network.name + "/MultiHonor.sol:MultiHonor_Multichain";
  let SBT_Logic = await ethers.getContractFactory(MultiHonor_Multichain);
  let sbt_logic = await SBT_Logic.deploy();
  console.log("sbt logic " + sbt_logic.address);
  await sbt_logic.deployed();

  // TODO update SBT
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
