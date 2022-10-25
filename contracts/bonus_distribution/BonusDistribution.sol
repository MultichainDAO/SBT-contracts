// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DateTime.sol";

interface IBonusDistributor {
    event ClaimBonus(uint256 idcard, address toAccount, uint256 amount);

    function claimable(uint256 idcard) external view returns (uint256 amount);

    function claim(uint256 idcard, address toAccount)
        external
        returns (uint256 amount);
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IIDNFT {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface IMultiHonor {
    function POC(uint256 tokenId) external view returns (uint64);
}

abstract contract Administrable {
    address public admin;
    address public pendingAdmin;

    event SetAdmin(address admin);
    event TransferAdmin(address pendingAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function _setAdmin(address admin_) internal {
        admin = admin_;
        emit SetAdmin(admin);
    }

    function transferAdmin(address admin_) external onlyAdmin {
        pendingAdmin = admin_;
        emit TransferAdmin(pendingAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        _setAdmin(pendingAdmin);
        pendingAdmin = address(0);
    }
}

abstract contract AdminPausable is Administrable {
    bool public paused;

    event Pause();

    modifier mustNotPaused() {
        require(!paused);
        _;
    }

    modifier mustPaused() {
        require(paused);
        _;
    }

    function _pause(bool pause_) internal {
        paused = pause_;
        emit Pause();
    }

    function setPaused(bool pause_) external onlyAdmin {
        _pause(pause_);
    }
}

contract MonthlyBonusDistributor is IBonusDistributor, AdminPausable, DateTime {
    address public bonusToken;
    address public idnft;
    address public multiHonor;
    uint256 public immutable bonusDay;

    mapping(uint256 => uint256) public historicPoints;

    event SetBonusToken(address bonusToken);
    event SetIDNFT(address idnft);
    event SetMultiHonor(address multiHonor);
    event Withdraw(uint256 amount, address to);

    constructor(
        address bonusToken_,
        address idnft_,
        address multiHonor_
    ) {
        bonusDay = 25;

        _setAdmin(msg.sender);
        _setBonusToken(bonusToken_);
        _setIDNFT(idnft_);
        _setMultiHonor(multiHonor_);
    }

    function _setBonusToken(address bonusToken_) internal {
        bonusToken = bonusToken_;
        emit SetBonusToken(bonusToken);
    }

    function _setIDNFT(address idnft_) internal {
        idnft = idnft_;
        emit SetIDNFT(idnft);
    }

    function _setMultiHonor(address multiHonor_) internal {
        multiHonor = multiHonor_;
        emit SetMultiHonor(multiHonor);
    }

    function setBonusToken(address bonusToken_) external onlyAdmin mustPaused {
        _setBonusToken(bonusToken_);
    }

    function withdraw(uint256 amount, address to)
        external
        onlyAdmin
        mustPaused
    {
        bool succ = IERC20(bonusToken).transfer(to, amount);
        require(succ);
        emit Withdraw(amount, to);
    }

    function currentMonthStart() public view returns (uint256 time) {
        uint16 y = getYear(block.timestamp);
        uint8 m = getMonth(block.timestamp);
        return toTimestamp(y, m, 1);
    }

    function claimable(uint256 idcard)
        public
        view
        override
        returns (uint256 amount)
    {
        if (
            block.timestamp <
            currentMonthStart() + (bonusDay - 1) * DAY_IN_SECONDS
        ) {
            return 0;
        }
        uint256 dpoc = getDpoc(idcard);
        uint8 decimal = IERC20(bonusToken).decimals();
        amount = dpoc * 10**decimal;
        return amount;
    }

    function getDpoc(uint256 idcard) public view returns (uint256 dpoc) {
        uint256 poc = uint256(IMultiHonor(multiHonor).POC(idcard));
        dpoc = poc > historicPoints[idcard] ? poc - historicPoints[idcard] : 0;
        return dpoc;
    }

    function claim(uint256 idcard, address toAccount)
        external
        override
        mustNotPaused
        returns (uint256 amount)
    {
        require(
            IIDNFT(idnft).ownerOf(idcard) == msg.sender,
            "bonus distributor: not idcard owner"
        );
        if (
            block.timestamp <
            currentMonthStart() + (bonusDay - 1) * DAY_IN_SECONDS
        ) {
            return 0;
        }
        uint256 dpoc = getDpoc(idcard);
        uint8 decimal = IERC20(bonusToken).decimals();
        amount = dpoc * 10**decimal;
        bool success = IERC20(bonusToken).transfer(toAccount, amount);
        require(success, "bonus distributor: send bonus token failed");
        historicPoints[idcard] += dpoc;
        emit ClaimBonus(idcard, toAccount, amount);
        return amount;
    }
}
