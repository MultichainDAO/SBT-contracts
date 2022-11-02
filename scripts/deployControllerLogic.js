const hre = require("hardhat");

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("owner " + owner.address);

    console.log("\ndeploy IDCard_V2_Controller logic");
    let Controller = await ethers.getContractFactory("IDCard_V2_Controller");
    let controller = await Controller.deploy();
    await controller.deployed();
    console.log("controller " + controller.address);
    // TODO update in proxy admin\
    // TODO initV2Controller if is upgraded from V1
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
