### DID layer
IDNFT 可以通过插入式的适配器连接外部 DID provider，使 IDNFT 成为综合的 DID 系统。
适配器负责保存 IDNFT 和外部 DID 的映射关系，
controller 合约通过插入式验证器校验 IDNFT 的认证信息。
可信任的外部 DID provider 包括 BABT, Premium holder, While holder, Remote user adaptor 等。
IDNFT controller 可以管理多种受信任的外部 DID 系统，
连接了外部 DID 的 IDNFT holder 会被看作真实用户。
#### 1. BABT adaptor
- Key - `BABT`
- Hash - `0xb63a497d1f0a88a115a9861e337eae338d0a7c9d5d6b92166cd4e1c7714d353e`
- Sign info - `getSignInfo(babtId)` in the contract `BABTAdaptor`
配置了 BABT adaptor 后，IDNFT 可以通过 BABT 和 Binance 用户建立关联，
要求 IDNFT holder 同时也是 BABT holder。
IDNFT 转移到新钱包地址后关联自动失效。
#### 2. Premium holder adaptor
- Key - `Premium`
- Hash - `0b28050d05d9fba190ff5656d934c93e58319a3c5b73c5c30a97cd17e52b5a97`
- Sign info - not needed
配置了 Premium holder adaptor 后，IDNFT holder 可以支付 token 成为 Premium holder.
IDNFT 转移到新钱包地址后 Premium holder 自动失效。
#### 3. White holder adaptor
- Key - `White`
- Hash - `d8be6abfb290c7325c2b3f8da08d37efd1ef2b5da915d00ba3bd068eaab2e770`
- Sign info - generated offchain
配置了 White holder adaptor 后，IDNFT holder 会在管理员审核后被添加进 MMR 白名单，
IDNFT holder 可以提供 MMR inclusion 证明，成为 White holder.
IDNFT 转移到新钱包地址后 White holder 自动失效。
#### 4. Remote user adaptor
用户的 IDNFT 可以注册到多条链上。如果用户的 IDNFT 已在在一条链上绑定了 DID，可以通过 Remote user adaptor
向外链发送绑定消息，使用户在外链上也成为受信任用户。

用户需要进行多步操作，
1. 调用 controller 合约上的 register 函数，把 IDNFT 注册到外链.
2. 调用 connect 函数，选一种 DID 适配器类型，对将 IDNFT 和 DID 绑定.
3. 在 RemoteUserAdaptor 合约中调用 submitVerifyInfo 函数，把 verify 消息传递到外链.
4. 消息传到后，在目的链上用相同的钱包地址调用 controller 合约的 connect 函数，选择 keccak256("RemoteUser") 作为 account type，完成绑定.