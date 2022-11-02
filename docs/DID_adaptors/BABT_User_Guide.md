### 1. Connect IDNFT to BABT
1. Get sign info with function `getSignInfo(babtId)` in the contract `BABTAdaptor` with the account holding the BABT.
2. Find the account type hash of BABT, which is `0xb63a497d1f0a88a115a9861e337eae338d0a7c9d5d6b92166cd4e1c7714d353e`.
3. Claim IDNFT with the same wallet in the contract `IDCard_V2_Controller`
```
claim(bytes32 accountType, bytes memory sign_info)
```
Alternatively, user can claim IDNFT with blank sign info and connect to BABT later with the function `updateAccountInfo`.
### 2. Check if IDNFT is bound to a BABT
Call the function `verifyAccount(tokenId)` in the contract `IDCard_V2_Controller`.
### 3. Disconnect IDNFT to BABT
Call the function `disconnect(tokenId)` in the contract `IDCard_V2_Controller`.