const hre = require("hardhat");

// bsc
/*
let idcard = "0x3E05584358f0Fbfc1909aDE5aCfFBAB7842BdfDc";
let controller = "0x81DCd47EdAD7e30864C7d3f84032368954889B90";
let money = "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"; // Binance-Peg USDC
let price = "5000000000000000000" // 5 USDC
let proxyAdmin = "0xC65D11676A210f7116be4D7b86bCc5F30fB2565F";
*/

// polygon
let idcard = "0x7a02492bAa66B0b8266a6d25Bbd6D8BA169296CC";
let controller = "0xB89a2Fa1efB5BcEcd813319c99711cc15DCa2C00";
let money = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174"; // Polygon PoS USDC
let price = "5000000" // 5 USDC
let proxyAdmin = "0xe7E22Ad06493b97dd86875C7F59f0d71C664c75E";

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("owner " + owner.address);

    console.log("\ndeploy premium adaptor");

    let i_init = new ethers.utils.Interface(["function initialize()"]);

    let initdata = i_init.encodeFunctionData("initialize");
    console.log("initdata " + initdata);

    let Adaptor = await ethers.getContractFactory("PremiumHolder");
    let adaptor_logic = await Adaptor.deploy();
    await adaptor_logic.deployed();
    console.log("usdc premium adaptor_logic " + adaptor_logic.address);

    const Proxy = await ethers.getContractFactory("contracts/proxy/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy");
    let adaptor_proxy = await Proxy.deploy(adaptor_logic.address, proxyAdmin, initdata);
    await adaptor_proxy.deployed();

    let adaptor = await ethers.getContractAt("PremiumHolder", adaptor_proxy.address);
    console.log("adaptor " + adaptor.address);

    let rc = await adaptor.initAdaptor(idcard, controller, money, price);
    await rc.wait();
    console.log(`init adaptor : ${JSON.stringify(rc)}`);
    // TODO register usdc premium adaptor in the controller
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
