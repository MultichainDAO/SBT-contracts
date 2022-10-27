// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const proxyAdminAddrs = {
  "polygon": "0xe7E22Ad06493b97dd86875C7F59f0d71C664c75E"
}

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("owner " + owner.address);

  let proxyAdmin = await ethers.getContractAt("ProxyAdmin", proxyAdminAddrs[hre.network.name]);
  console.log("proxyAdmin " + proxyAdmin.address);

  console.log("\ndeploy idnft");
  let IDNFT_Logic = await ethers.getContractFactory("IDCard_V2");
  let idnft_logic = await IDNFT_Logic.deploy();
  console.log("idnft logic " + idnft_logic.address);

  // TODO update idnft

  console.log("\ndeploy controller");
  let Controller_Logic = await ethers.getContractFactory("IDCard_V2_Controller");
  let controller_logic = await Controller_Logic.deploy();
  console.log("controller logic " + controller_logic.address);

  let controller_proxy = await Proxy.deploy(controller_logic.address, proxyAdmin.address, initdata);
  console.log("controller proxy " + controller_proxy.address);

  let controller = await ethers.getContractAt("IDCard_V2_Controller", controller_proxy.address);
  console.log("controller address " + controller.address);

  // TODO grant idnft controller role
  // TODO init idnft

  console.log("\ngrant controller admin role");
  await controller.grantRole(role_admin, owner.address);
  expect(await idnft.hasRole(role_admin, owner.address)).to.equal(true);

  console.log("\ndeploy SBT");
  let MultiHonor_Multichain = "contracts/SBT/" + hre.network.name + "/MultiHonor.sol:MultiHonor_Multichain";
  let SBT_Logic = await ethers.getContractFactory(MultiHonor_Multichain);
  let sbt_logic = await SBT_Logic.deploy();
  console.log("sbt logic " + sbt_logic.address);

  // TODO update SBT
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
