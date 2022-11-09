const hre = require("hardhat");

async function main() {
    const [owner] = await ethers.getSigners();
    console.log("owner " + owner.address);

    let Accumulator = await ethers.getContractFactory("Non_Trivial_Accumulator");
    let accumulator = await Accumulator.deploy("0xDd98B79b36c77Ee1F23f37B61e58A61cc3D5aceF"); // polygon
    await accumulator.deployed();
    console.log("accumulator " + accumulator.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
