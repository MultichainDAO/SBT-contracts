// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @dev Interface for DAO subsystems that depend on idcard, eg MultiHonor
 */
interface ILedger {
    /// @dev A hook function that executes when IDCards got merged.
    function merge(uint256 fromToken, uint256 toToken) external virtual;
}

/**
 * @dev Interface of crosschain message channel.
 */
interface IMessageChannel {
    function send(
        uint256 toChainID,
        address to,
        bytes memory message
    ) external virtual;
}

/**
 * @dev Interface for DID adaptor.
 * Allow DAO users to sign up with 3rd party DID protocols, eg Binance SBT, ENS, etc.
 */
interface IDIDAdaptor {
    function connect(
        uint256 tokenId,
        address claimer,
        bytes32 accountType,
        bytes memory sign_info
    ) external returns (bool);

    function verifyAccount(uint256 tokenId) external view returns (bool);

    function disconnect(uint256 tokenId) external virtual returns (bool);
}

interface INFT {
    function mint(address owner, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function exists(uint256 tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

/**
 * @notice ID card controller allow DAO users to
 * claim ID card,
 * connect and disconnect idcard with 3rd party DID account,
 * register to remote chains,
 * merge idcards.
 */
contract IDCard_V2_Controller is AccessControlUpgradeable {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_MESSAGE = keccak256("ROLE_MESSAGE");

    bool v2Initialized;

    uint256 maxTokenIdId;
    uint256 public nextTokenId;

    address public idnft;

    /// @dev Message channel adaptor address.
    address public messageChannel;
    /// @dev Peer chains.
    uint256[] public chains;
    mapping(uint256 => address) public peer;
    bytes4 public constant FuncMerge = bytes4(keccak256("merge"));
    bytes4 public constant FuncRegister = bytes4(keccak256("register"));

    /// @dev Type of DID that IDCard is connected to.
    mapping(uint256 => bytes32) public accountTypeOf;
    /// @dev Default account type.
    bytes32 constant AccountType_Default = bytes32("Default");
    /// @dev DID adaptor contracts for different DID types.
    mapping(bytes32 => address) public dIDAdaptor;

    /// @dev A list of MultiDAO subsystem contracts.
    address[] public ledgers;

    event InitV2Controller();

    event SetNFT(address idnft);

    event SetMessageChannel(address messageChannel);
    event SetChains(uint256[] chains);
    event SetPeer(address peer, uint256 ChainID);

    event SetDIDAdaptor(string key, bytes32 hashkey, address adaptor);

    event RegisterLedger(address ledger);
    event RemoveLedger(address ledger);

    event Claim(uint256 tokenId, address owner);
    event Connect(uint256 tokenId, bytes32 accountType, bytes signinfo);
    event Disconnect(uint256 tokenId, bytes32 accountType);

    event RegisterRequest(
        uint256 tokenId,
        uint256[] toChainIDs,
        address receiverWallet
    );
    event Register(uint256 tokenId, address receiverWallet);

    event MergeLocal(uint256 fromToken, uint256 toToken);
    event Merge(uint256 fromToken, uint256 toToken);
    event MergeError(address ledger, uint256 fromToken, uint256 toToken);

    modifier mustInitialized() {
        require(v2Initialized);
        _;
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __initRole();
    }

    function __initRole() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Initializes V2 settings.
    function initV2Controller(address idnft, address messageChannel_) public {
        _checkRole(ROLE_ADMIN);
        require(!v2Initialized);
        maxTokenIdId = 1000000000;
        _setNFT(idnft);
        _setMessageChannel(messageChannel_);
        v2Initialized = true;
        emit InitV2Controller();
    }

    /// @dev Sets IDNFT.
    function setNFT(address idnft) external {
        _checkRole(ROLE_ADMIN);
        _setNFT(idnft);
    }

    function _setNFT(address idnft_) internal {
        idnft = idnft_;
        emit SetNFT(idnft_);
    }

    /// @dev Sets message channel (adaptor) address.
    function setMessageChannel(address messageChannel_) external {
        _checkRole(ROLE_ADMIN);
        _setMessageChannel(messageChannel_);
    }

    function _setMessageChannel(address messageChannel_) internal {
        if (messageChannel != address(0)) {
            _revokeRole(ROLE_MESSAGE, messageChannel);
        }
        messageChannel = messageChannel_;
        _grantRole(ROLE_MESSAGE, messageChannel);
        emit SetMessageChannel(messageChannel);
    }

    /// @dev Sets peer chains.
    function setChains(uint256[] memory chains_) external {
        _checkRole(ROLE_ADMIN);
        chains = chains_;
        emit SetChains(chains);
    }

    /// @dev Sets remote caller's permission.
    function setPeer(address peer_, uint256 chainID) external {
        _checkRole(ROLE_ADMIN);
        peer[chainID] = peer_;
        emit SetPeer(peer_, chainID);
    }

    /// @dev Sets DID adaptor address.
    function setDIDAdaptor(string memory key, address adaptor) public {
        _checkRole(ROLE_ADMIN);
        dIDAdaptor[keccak256(bytes(key))] = adaptor;
        emit SetDIDAdaptor(key, keccak256(bytes(key)), adaptor);
    }

    /// @dev Returns DID type hash.
    function dIDType(string memory key) public pure returns (bytes32) {
        return keccak256(bytes(key));
    }

    /// @dev Register ledger.
    function registerLedgers(address ledger) external {
        _checkRole(ROLE_ADMIN);
        for (uint256 i = 0; i < ledgers.length; i++) {
            if (ledgers[i] == ledger) {
                revert("already exists");
            }
        }
        ledgers.push(ledger);
        emit RegisterLedger(ledger);
    }

    /// @dev Remove ledger.
    function removeLedger(address ledger) external {
        _checkRole(ROLE_ADMIN);
        uint256 index = 0;
        for (uint256 i = 0; i < ledgers.length; i++) {
            if (ledgers[i] == ledger) {
                index = i + 1;
                break;
            }
        }
        index--;
        for (uint256 i = index; i < ledgers.length - 1; i++) {
            ledgers[i] = ledgers[i + i];
        }
        ledgers.pop();
        emit RemoveLedger(ledger);
    }

    /// @dev Dispatches message to different functions.
    function onReceiveMessage(
        address caller,
        uint256 fromChainID,
        bytes memory message
    ) external mustInitialized {
        _checkRole(ROLE_MESSAGE);
        (bytes4 func, bytes memory args) = abi.decode(message, (bytes4, bytes));
        if (func == FuncMerge) {
            require(caller == peer[fromChainID]);
            onMergeMessage(args);
            return;
        }
        if (func == FuncRegister) {
            require(caller == peer[fromChainID]);
            onRegisterMessage(args);
            return;
        }
    }

    /// @dev Returns birth chain of the IDCard.
    function getChainID(uint256 tokenId) public view returns (uint256 chainID) {
        chainID = tokenId / maxTokenIdId;
        if (chainID == 0) {
            chainID = 137;
        }
        return chainID;
    }

    /**
     * @dev Mints NFT to msg sender.
     * @param accountType DID protocol type, eg whitelist, ENS holder checker, Binance SBT holder checker.
     * @param sign_info DID account verification info.
     */
    function claim(bytes32 accountType, bytes memory sign_info)
        external
        mustInitialized
        returns (uint256 tokenId)
    {
        tokenId = nextTokenId;
        tokenId = tokenId + block.chainid * maxTokenIdId;
        require(_connect(tokenId, accountType, sign_info));
        INFT(idnft).mint(msg.sender, tokenId);
        nextTokenId++;
        emit Claim(tokenId, msg.sender);
    }

    /**
     * @dev Connect a DID account.
     * @param accountType DID protocol type, eg MultiDAO whitelisted address, ENS holder, Binance BABT holder.
     * @param sign_info DID account verification info.
     */
    function _connect(
        uint256 tokenId,
        bytes32 accountType,
        bytes memory sign_info
    ) internal virtual returns (bool res) {
        require(accountTypeOf[tokenId] == bytes32(0));
        if (accountType == AccountType_Default) {
            res = true;
            return res;
        }
        res = IDIDAdaptor(dIDAdaptor[accountType]).connect(
            tokenId,
            msg.sender,
            accountType,
            sign_info
        );
        if (res) {
            accountTypeOf[tokenId] = accountType;
        }
        emit Connect(tokenId, accountType, sign_info);
        return res;
    }

    /// @dev Verifies if the IDCard holder is the owner of DID that is currently connecting to the IDCard.
    function verifyAccount(uint256 tokenId) public view virtual returns (bool) {
        bytes32 accountType = accountTypeOf[tokenId];
        if (accountType == AccountType_Default) {
            return false;
        }
        return IDIDAdaptor(dIDAdaptor[accountType]).verifyAccount(tokenId);
    }

    /// @dev Connect to DID.
    function connect(
        uint256 tokenId,
        bytes32 newAccountType,
        bytes memory new_sign_info
    ) public {
        _connect(tokenId, newAccountType, new_sign_info);
    }

    /// @dev Update idcard's DID.
    function updateAccountInfo(
        uint256 tokenId,
        bytes32 newAccountType,
        bytes memory new_sign_info
    ) public {
        require(
            msg.sender == INFT(idnft).ownerOf(tokenId),
            "check token owner fail"
        );
        disconnect(tokenId);
        _connect(tokenId, newAccountType, new_sign_info);
    }

    /// @dev Disconnect idcard with DID.
    function disconnect(uint256 tokenId) public returns (bool res) {
        require(msg.sender == INFT(idnft).ownerOf(tokenId));
        res = IDIDAdaptor(dIDAdaptor[accountTypeOf[tokenId]]).disconnect(
            tokenId
        );
        if (res) {
            accountTypeOf[tokenId] = bytes32(0);
        }
        emit Disconnect(tokenId, accountTypeOf[tokenId]);
    }

    /**
     * @dev Merges 2 idcards on all chains.
     * Merges tokens locally and send merge message to remote chains.
     */
    function merge(uint256 fromToken, uint256 toToken)
        external
        mustInitialized
    {
        require(
            msg.sender == INFT(idnft).ownerOf(fromToken),
            "check token owner fail"
        );
        require(INFT(idnft).exists(toToken));
        _merge(fromToken, toToken);
        bytes memory args = abi.encode(fromToken, toToken);
        bytes memory message = abi.encode(FuncMerge, args);
        for (uint256 i = 0; i < chains.length; i++) {
            IMessageChannel(messageChannel).send(
                chains[i],
                peer[chains[i]],
                message
            );
        }
        emit MergeLocal(fromToken, toToken);
    }

    function onMergeMessage(bytes memory message) internal {
        (uint256 fromToken, uint256 toToken) = abi.decode(
            message,
            (uint256, uint256)
        );
        _merge(fromToken, toToken);
    }

    /**
     * @dev Merges 2 idcards locally.
     */
    function _merge(uint256 fromToken, uint256 toToken) internal {
        if (!INFT(idnft).exists(fromToken) || !INFT(idnft).exists(toToken)) {
            return;
        }
        mergeLedgers(fromToken, toToken);
        INFT(idnft).burn(fromToken);
        emit Merge(fromToken, toToken);
    }

    /// @dev Calls registered ledgers to merge tokens.
    function mergeLedgers(uint256 fromToken, uint256 toToken) internal {
        require(fromToken != toToken);
        require(INFT(idnft).exists(toToken));
        for (uint256 i = 0; i < ledgers.length; i++) {
            try ILedger(ledgers[i]).merge(fromToken, toToken) {} catch {
                emit MergeError(ledgers[i], fromToken, toToken);
            }
        }
    }

    /// @dev Register to remote chains.
    function register(
        uint256 tokenId,
        uint256[] calldata toChainIDs,
        address receiverWallet
    ) external mustInitialized {
        require(msg.sender == INFT(idnft).ownerOf(tokenId));
        bytes memory args = abi.encode(tokenId, receiverWallet);
        bytes memory message = abi.encode(FuncRegister, args);
        for (uint256 i = 0; i < toChainIDs.length; i++) {
            IMessageChannel(messageChannel).send(
                chains[i],
                peer[chains[i]],
                message
            );
        }
        emit RegisterRequest(tokenId, toChainIDs, receiverWallet);
    }

    function onRegisterMessage(bytes memory message) internal {
        (uint256 tokenId, address receiverWallet) = abi.decode(
            message,
            (uint256, address)
        );
        INFT(idnft).mint(receiverWallet, tokenId);
        emit Register(tokenId, receiverWallet);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override
        returns (bool)
    {
        return false;
    }
}
