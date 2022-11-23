const hre = require("hardhat");

let idcard = "0x3E05584358f0Fbfc1909aDE5aCfFBAB7842BdfDc";
let controller = "0x81DCd47EdAD7e30864C7d3f84032368954889B90";
let babt = "0x2b09d47d550061f995a3b5c6f0fd58005215d7c8";
let proxyAdmin = "0xC65D11676A210f7116be4D7b86bCc5F30fB2565F";

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("owner " + owner.address);

    if (hre.network.name !== "bsc") {
        console.error("network must be bsc");
        return;
    }

    console.log("\ndeploy babt adaptor");
    let i_init = new ethers.utils.Interface(["function initialize()"]);

    let initdata = i_init.encodeFunctionData("initialize");
    console.log("initdata " + initdata);
    let BABTAdaptor = await ethers.getContractFactory("BABTAdaptor");
    let babtAdaptor_logic = await BABTAdaptor.deploy();
    await babtAdaptor_logic.deployed();
    console.log("babtAdaptor_logic " + babtAdaptor_logic.address);

    const Proxy = await ethers.getContractFactory("contracts/proxy/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy");
    let babtAdaptor_proxy = await Proxy.deploy(babtAdaptor_logic.address, proxyAdmin, initdata);
    await babtAdaptor_proxy.deployed();
    console.log("babtAdaptor_proxy " + babtAdaptor_proxy.address);

    let babtAdaptor = await ethers.getContractAt("BABTAdaptor", babtAdaptor_proxy.address);
    console.log("babtAdaptor " + babtAdaptor.address);

    let rc = await babtAdaptor.initAdaptor(idcard, controller, babt);
    await rc.wait();
    console.log(`init adaptor : ${JSON.stringify(rc)}`);
    // TODO register BABT adaptor in the controller
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
