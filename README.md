# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

# MultiDAO contracts

## Architecture
![image](Architecture.png)

## ID NFT features
### Claimable on multiple chains
ID NFT serves as the account system of MultiDAO. ID NFTs are claimable on all supported
chains with a different prefix, so the token ID is unique in the entire Multiverse.

### Register to remote chain

### Binding to accounts of other digital identity protocol
The controller contract allows ID NFT holders to prove they are real users by
connecting to a digital identity (DID) account. It utilizes adaptors to interact
with 3rd party DID providers.

The first supported DID system is BABT.

Upper-layer applications (like SBT and reward distributor) can retrieve underlying DID
information of ID NFTs in the controller contract and the adaptor contract.