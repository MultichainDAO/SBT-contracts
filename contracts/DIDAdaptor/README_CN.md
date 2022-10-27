### DID adaptor
IDNFT 可以通过连接插入式的验证器成为 DAO 的认证用户。
插入式验证器负责保存 IDNFT 和外部系统的账户的映射关系，
controller 合约通过插入式验证器校验 IDNFT 的认证信息。
可信任的外部验证器包括 BABT adaptor, Premium holder, While holder 等。
IDNFT controller 可以管理多种受信任的外部 DID 系统，
连接了外部 DID 的 IDNFT holder 会被看作真实用户。
#### 1. BABT adaptor
配置了 BABT adaptor 后，IDNFT 可以通过 BABT 和 Binance 用户建立关联，
要求 IDNFT holder 同时也是 BABT holder。
IDNFT 转移到新钱包地址后关联自动失效。
#### 2. Premium holder adaptor
配置了 Premium holder adaptor 后，IDNFT holder 可以支付 token 成为 Premium holder.
IDNFT 转移到新钱包地址后 Premium holder 自动失效。
#### 3. White holder adaptor
配置了 White holder adaptor 后，IDNFT holder 会在管理员审核后被添加进 MMR 白名单，
IDNFT holder 可以提供 MMR inclusion 证明，成为 White holder.
IDNFT 转移到新钱包地址后 White holder 自动失效。