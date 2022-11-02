const hre = require("hardhat");

/*
// bsc
let idcard = "0x3E05584358f0Fbfc1909aDE5aCfFBAB7842BdfDc";
let controller = "0x81DCd47EdAD7e30864C7d3f84032368954889B90";
let money = "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"; // Binance-Peg USDC
let price = "5000000000000000000" // 5 USDC
*/

// polygon
let idcard = "0x7a02492bAa66B0b8266a6d25Bbd6D8BA169296CC";
let controller = "0xB89a2Fa1efB5BcEcd813319c99711cc15DCa2C00";
let money = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174"; // Polygon PoS USDC
let price = "5000000" // 5 USDC

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("owner " + owner.address);

    console.log("\ndeploy premium adaptor");
    let Adaptor = await ethers.getContractFactory("PremiumHolder");
    let adaptor = await Adaptor.deploy(idcard, controller, money, price);
    await adaptor.deployed();
    console.log("usdc premium adaptor " + adaptor.address);
    // TODO register usdc premium adaptor in the controller
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
