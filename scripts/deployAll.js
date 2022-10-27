// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("owner " + owner.address);

  console.log("\ndeploy proxy admin");
  let ProxyAdmin = await ethers.getContractFactory("ProxyAdmin");
  let proxyAdmin = await ProxyAdmin.deploy();
  console.log("proxy admin " + proxyAdmin.address);

  console.log("\ndeploy idnft");
  let IDNFT_Logic = await ethers.getContractFactory("IDCard_V2");
  let idnft_logic = await IDNFT_Logic.deploy();
  setTimeout(() => { }, 3000);
  await idnft_logic.deployed();
  console.log("idnft logic " + idnft_logic.address);

  let i_init = new ethers.utils.Interface(["function initialize()"]);

  let idnftinitdata = i_init.encodeFunctionData("initialize");
  console.log("idnftinitdata " + idnftinitdata);

  const Proxy = await ethers.getContractFactory("contracts/proxy/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy");
  let idnft_proxy = await Proxy.deploy(idnft_logic.address, proxyAdmin.address, idnftinitdata);
  setTimeout(() => { }, 3000);
  await idnft_proxy.deployed();
  console.log("idnft_proxy " + idnft_proxy.address);

  let idnft = await ethers.getContractAt("IDCard_V2", idnft_proxy.address);
  console.log("idnft " + idnft.address);

  // TODO initV2
  // TODO grant admin role

  console.log("\ndeploy controller");
  let Controller_Logic = await ethers.getContractFactory("IDCard_V2_Controller");
  let controller_logic = await Controller_Logic.deploy();
  setTimeout(() => { }, 3000);
  await controller_logic.deployed();
  console.log("controller logic " + controller_logic.address);

  let controllerinitdata = i_init.encodeFunctionData("initialize");
  console.log("controllerinitdata " + controllerinitdata);

  let controller_proxy = await Proxy.deploy(controller_logic.address, proxyAdmin.address, controllerinitdata);
  setTimeout(() => { }, 3000);
  await controller_proxy.deployed();
  console.log("controller proxy " + controller_proxy.address);

  // TODO init v2 controller
  // TODO grant controller role to controller in idnft
  // TODO grant admin role
  // TODO register DID providers

  console.log("\ndeploy SBT");
  let MultiHonor_Multichain = "contracts/SBT/" + (hre.network.name == 'hardhat' ? 'polygon' : hre.network.name) + "/MultiHonor.sol:MultiHonor_Multichain";
  let SBT_Logic = await ethers.getContractFactory(MultiHonor_Multichain);
  let sbt_logic = await SBT_Logic.deploy();
  setTimeout(() => { }, 3000);
  await sbt_logic.deployed();
  console.log("sbt logic " + sbt_logic.address);

  let sbtinitdata = i_init.encodeFunctionData("initialize");
  console.log("sbtinitdata " + sbtinitdata);

  let sbt_proxy = await Proxy.deploy(sbt_logic.address, proxyAdmin.address, sbtinitdata);
  setTimeout(() => { }, 3000);
  await sbt_proxy.deployed();
  console.log("sbt proxy " + sbt_proxy.address);

  let sbt = await ethers.getContractAt(MultiHonor_Multichain, sbt_proxy.address);
  await sbt.deployed();
  console.log("sbt address " + sbt.address);

  // TODO set IDCard in sbt
  // TODO set controller in sbt
  // TODO sbt controller as ledger in controller
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
