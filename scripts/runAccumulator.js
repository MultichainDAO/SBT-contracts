const { ethers } = require("hardhat");
const hre = require("hardhat");

const idnftAddress = '0x7a02492bAa66B0b8266a6d25Bbd6D8BA169296CC';
//const accumulatorAddress = '0x733df3b8c55Eb99EAc66fbD621c9664dD7d9667F';
const accumulatorAddress = '0x6b1a19d77a76bcC2B3336A7D8049Ec67a39FbA89';

async function main() {
    let idnft = await ethers.getContractAt("IDCard_V2", idnftAddress);
    let totalSupply = await idnft.totalSupply();
    console.log(totalSupply);

    let old = 15376;
    let step = 500;

    let counter = await ethers.getContractAt("Non_Trivial_Accumulator", accumulatorAddress);
    var acc = 0;
    for (var i = 0; i * step < old; i++) {
        var dacc = await counter.get(i * step, (i + 1) * step);
        acc = Number(acc) + Number(dacc);
        setTimeout(() => { }, 500);
        console.debug(`i : ${i}, acc : ${acc}`);
    }
    for (var i = 0; i * step < totalSupply - old; i++) {
        var dacc = await counter.get(i * step + 137000000000, (i + 1) * step + 137000000000);
        acc = Number(acc) + Number(dacc);
        setTimeout(() => { }, 500);
        console.debug(`i : ${i}, acc : ${acc}`);
    }
    console.log(`acc : ${acc}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
