// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IMultiHonor {
    function POC(uint256 tokenId) external view returns (uint64);

    function VEPower(uint256 tokenId) external view returns (uint256);

    function VEPoint(uint256 tokenId) external view returns (uint64);

    function EventPoint(uint256 tokenId) external view returns (uint64);

    function TotalPoint(uint256 tokenId) external view returns (uint64);

    function Level(uint256 tokenId) external view returns (uint8);
}

interface IERC721Enumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

interface ILedger {
    /// @dev A hook function that executes when IDCards got merged.
    function merge(uint256 fromToken, uint256 toToken) external virtual;
}

contract MultiHonor_Multichain is
    Initializable,
    IMultiHonor,
    AccessControlUpgradeable,
    ILedger
{
    /// @dev not required and not allowed if upgrading from v1
    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __initRole();
        __initSBT();
        __initVEEpoch();
    }

    address public IDCard;
    bytes32 public constant ROLE_ADD_POC = keccak256("ROLE_ADD_POC");
    bytes32 public constant ROLE_SET_POC = keccak256("ROLE_SET_POC");
    bytes32 public constant ROLE_SET_VEPOWER = keccak256("ROLE_SET_VEPOWER");
    bytes32 public constant ROLE_ADD_EVENT = keccak256("ROLE_ADD_EVENT");
    bytes32 public constant ROLE_SET_EVENT = keccak256("ROLE_SET_EVENT");

    function __initRole() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    uint256 public weight_poc;
    uint256 public weight_vepoint;
    uint256 public weight_event;

    uint256 public k;
    uint256 constant k_denominator = 1000000;
    // uint256 constant p = 1000000000;

    uint256 public veEpochLength;

    event SetPoc(uint256[] ids, uint64[] poc);
    event AddPOC(uint256[] ids, uint64[] poc);
    event SetVEPower(uint256[] ids, uint256[] vePower, uint64 epoch);
    event SetEventPoint(uint256[] ids, uint64[] eventPower);
    event AddEventPoint(uint256[] ids, uint64[] eventPower);
    event SetIDCard(address idcard);
    event SetController(address controller);

    function resetSBT() external {
        // reset SBT params
        __initSBT();
    }

    function __initSBT() internal {
        weight_poc = 600;
        weight_vepoint = 300;
        weight_event = 100;
        k = 0;
    }

    function __initVEEpoch() internal {
        veEpochLength = 7257600; // 12 weeks
    }

    function setIDCard(address IDCard_) external {
        _checkRole(DEFAULT_ADMIN_ROLE);
        IDCard = IDCard_;
        emit SetIDCard(IDCard);
    }

    function setIDController(address controller_) external {
        _checkRole(DEFAULT_ADMIN_ROLE);
        controller = controller_;
        emit SetController(controller);
    }

    struct POCInfo {
        uint64 POC;
        uint64 timestamp;
    }

    struct VEInfo {
        uint256 VEPower;
        uint64 epoch;
    }

    mapping(uint256 => POCInfo) private pocInfo;
    mapping(uint256 => VEInfo) private veInfo;
    mapping(uint256 => uint64) private eventPoint;

    event Merge(uint256 fromToken, uint256 toToken);

    address public controller;

    function merge(uint256 fromToken, uint256 toToken) external override {
        require(msg.sender == controller);
        // Merge POC
        pocInfo[toToken].POC = this.POC(toToken) + this.POC(fromToken);
        pocInfo[toToken].timestamp = uint64(block.timestamp);
        pocInfo[fromToken].POC = 0;
        pocInfo[fromToken].timestamp = uint64(block.timestamp);
        // Merge veInfo
        if (veInfo[fromToken].epoch == uint64(currentVEEpoch())) {
            if (veInfo[toToken].epoch == uint64(currentVEEpoch())) {
                veInfo[toToken].epoch += veInfo[fromToken].epoch;
            } else {
                veInfo[toToken].epoch = veInfo[fromToken].epoch;
            }
        }
        // Merge event point
        eventPoint[toToken] += eventPoint[fromToken];
        eventPoint[fromToken] = 0;
        emit Merge(fromToken, toToken);
    }

    function currentVEEpoch() public view returns (uint256) {
        return block.timestamp / veEpochLength;
    }

    // returns user's POC at a specific time after checkpoint
    function POC_at(uint256 tokenId, uint256 time)
        external
        view
        returns (uint64)
    {
        return
            uint64(
                uint256(pocInfo[tokenId].POC) -
                    (uint256(time - pocInfo[tokenId].timestamp) * k) /
                    k_denominator
            );
        // Non linear attenuation
        // return p / (time - (pocInfo[tokenId].POCTimestamp - p / pocInfo[tokenId].POC));
    }

    // returns user's current POC
    function POC(uint256 tokenId) external view override returns (uint64) {
        return this.POC_at(tokenId, block.timestamp);
    }

    // returns user's average VEPower in current epoch
    function VEPower(uint256 tokenId) external view override returns (uint256) {
        if (currentVEEpoch() > veInfo[tokenId].epoch) {
            // VE Power Expired
            return 0;
        }
        return veInfo[tokenId].VEPower;
    }

    // returns user's VEPoint
    function VEPoint(uint256 tokenId) external view override returns (uint64) {
        return uint64(vePower2vePoint(this.VEPower(tokenId)));
    }

    // returns user's current EventPoint
    function EventPoint(uint256 tokenId)
        external
        view
        override
        returns (uint64)
    {
        return eventPoint[tokenId];
    }

    function levelRequire(uint256 level) public pure returns (uint64) {
        if (level == 5) {
            return 200000;
        }
        if (level == 4) {
            return 100000;
        }
        if (level == 3) {
            return 30000;
        }
        if (level == 2) {
            return 5000;
        }
        if (level == 1) {
            return 1000;
        }
    }

    // returns user's level
    function Level(uint256 tokenId) external view override returns (uint8) {
        if (this.TotalPoint(tokenId) > levelRequire(5)) {
            return 5;
        }
        if (this.TotalPoint(tokenId) > levelRequire(4)) {
            return 4;
        }
        if (this.TotalPoint(tokenId) > levelRequire(3)) {
            return 3;
        }
        if (this.TotalPoint(tokenId) > levelRequire(2)) {
            return 2;
        }
        if (this.TotalPoint(tokenId) > levelRequire(1)) {
            return 1;
        }
        return 0;
    }

    // returns user's total honor
    function TotalPoint(uint256 tokenId)
        external
        view
        override
        returns (uint64)
    {
        return
            uint64(
                (this.POC(tokenId) *
                    weight_poc +
                    this.VEPoint(tokenId) *
                    weight_vepoint +
                    this.EventPoint(tokenId) *
                    weight_event) / (weight_poc + weight_vepoint + weight_event)
            );
    }

    // @dev cover Poc point
    function setPOC(uint256[] calldata ids, uint64[] calldata poc) external {
        _checkRole(ROLE_SET_POC);
        for (uint256 i = 0; i < ids.length; i++) {
            pocInfo[ids[i]].POC = poc[i];
            pocInfo[ids[i]].timestamp = uint64(block.timestamp);
        }
        emit SetPoc(ids, poc);
    }

    // @dev increase Poc value and update Poc check time
    function addPOC(uint256[] calldata ids, uint64[] calldata poc) external {
        _checkRole(ROLE_ADD_POC);
        for (uint256 i = 0; i < ids.length; i++) {
            uint64 poc_ = this.POC(ids[i]) + poc[i];
            pocInfo[ids[i]].POC = poc_;
            pocInfo[ids[i]].timestamp = uint64(block.timestamp);
        }
        emit AddPOC(ids, poc);
    }

    // @dev set average VE power for current epoch
    function setVEPower(uint256[] calldata ids, uint256[] calldata vePower)
        external
    {
        _checkRole(ROLE_SET_VEPOWER);
        uint256 veepoch = currentVEEpoch();
        for (uint256 i = 0; i < ids.length; i++) {
            veInfo[ids[i]].VEPower = vePower[i];
            veInfo[ids[i]].epoch = uint64(veepoch);
        }
        emit SetVEPower(ids, vePower, uint64(veepoch));
    }

    function setEventPoint(uint256[] calldata ids, uint64[] calldata eventPower)
        external
    {
        _checkRole(ROLE_SET_EVENT);
        for (uint256 i = 0; i < ids.length; i++) {
            eventPoint[ids[i]] = eventPower[i];
        }
        emit SetEventPoint(ids, eventPower);
    }

    // @dev increase event power
    function addEventPoint(uint256[] calldata ids, uint64[] calldata eventPower)
        external
    {
        _checkRole(ROLE_ADD_EVENT);
        for (uint256 i = 0; i < ids.length; i++) {
            uint64 eventPoint_ = this.EventPoint(ids[i]) + eventPower[i];
            eventPoint[ids[i]] = eventPoint_;
        }
        emit AddEventPoint(ids, eventPower);
    }

    function vePower2vePoint(uint256 v) public pure returns (uint256) {
        return 125 * log_2((v / 1 ether + 1)**2) + (514 * v) / 1 ether / 1000;
    }

    function log_2(uint256 x) public pure returns (uint256 y) {
        y = 0;
        for (uint256 i = 0; i < 255; i++) {
            x = x >> 1;
            if (x == 0) {
                return y;
            }
            y++;
        }
        revert("log_2 max loops exceeded");
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256 balance)
    {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        try IERC721Enumerable(IDCard).tokenOfOwnerByIndex(account, 0) returns (
            uint256 tokenId
        ) {
            if (id == 0) {
                balance = uint256(this.TotalPoint(tokenId));
            }
            if (id == 1) {
                balance = uint256(this.POC(tokenId));
            }
            if (id == 2) {
                balance = uint256(this.VEPoint(tokenId));
            }
            if (id == 3) {
                balance = uint256(this.EventPoint(tokenId));
            }
            if (id == 4) {
                balance = uint256(this.Level(tokenId));
            }
        } catch {
            balance = 0;
        }

        return balance;
    }
}
