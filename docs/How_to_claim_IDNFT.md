### How to claim IDNFT
1. Select a DID type to sign up with. [DID layer](./DID_adaptors/DID_adaptors_CN.md).
2. Find the DID key and type hash.
3. Get the sign info if needed.
4. Call function `claim(bytes32 accountType, bytes memory sign_info)` on the controller contract.

### How to verify an IDNFT is owned by a valid owner
Call function `verifyAccount(uint256 tokenId)` in the controller contract.

### How to integrate claim function in front end
#### BABT (only on BSC)
1. Let the user connect his wallet to the app.
2. Check if the user owns an IDNFT or not with function `ownerOf(uint256 tokenId)` in the contract `IDNFT`.
3. Check if the user owns a BABT with function `balanceOf` and `tokenOfOwnerByIndex(address owner,uint256 index)` in BABT. Disable the option if he doesn't have one.
4. Get the BABT adaptor contract address by `dIDAdaptor(bytes32 typeHash)` in the controller contract, where type hash is `0xb63a497d1f0a88a115a9861e337eae338d0a7c9d5d6b92166cd4e1c7714d353e`. 
5. Get user's sign info with `getSigninfo(babtId)` in the contract.
6. Allow the user to send a transaction to call `claim(bytes32 accountType, bytes memory sign_info)` in the controller contract.

#### Pay USDC to claim
1. Get the premium adaptor contract address with `dIDAdaptor(bytes32)` in the controller contract, where type hash is `0b28050d05d9fba190ff5656d934c93e58319a3c5b73c5c30a97cd17e52b5a97`.
2. Get token address and price with `money() uint256` adn `price() returns uint256` in the premium adaptor contract.
3. Approve money to the premium adaptor.
4. Send a transaction to call `claim(bytes32 accountType, bytes memory sign_info)` in the controller contract. `sign_info` is an empty string.

[Example](https://bscscan.com/tx/0xa4e2b5c8d541dd196b46984c805dc7cb03064211b212ad14598f0a64b1a87001)

#### Advanced
If user transfers his IDNFT to a new wallet, the IDNFT will lose the DID info. Front end program can check the status with `verifyAccount(idnft)` in the controller contract. The new owner can connect to a new DID of different types by `updateAccountInfo` in the controller contract.
