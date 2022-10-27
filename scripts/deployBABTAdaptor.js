const hre = require("hardhat");

let idcard = "0x3E05584358f0Fbfc1909aDE5aCfFBAB7842BdfDc";
let controller = "0x81DCd47EdAD7e30864C7d3f84032368954889B90";
let babt = "0x2b09d47d550061f995a3b5c6f0fd58005215d7c8";

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("owner " + owner.address);

    if (hre.network.name !== "bsc") {
        console.error("network must be bsc");
        return;
    }

    console.log("\ndeploy babt adaptor");
    let BABTAdaptor = await ethers.getContractFactory("BABTAdaptor");
    let babtAdaptor = await BABTAdaptor.deploy(idcard, controller, babt);
    await babtAdaptor.deployed();
    console.log("babtAdaptor " + babtAdaptor.address);
    // TODO register BABT adaptor in the controller
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
