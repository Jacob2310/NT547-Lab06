// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 24520903. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Treasury_0903 {
    address public owner;
    mapping(address => uint256) public balances;
    IERC20Like public rewardToken;
    mapping(address => uint256) public tokenCredit;
    bool private busy;
    mapping(address => uint256) public parked;

    event Deposited(address indexed who, uint256 amount);

    modifier onlyOwner() {
        require(tx.origin == owner, "not owner");
        _;
    }

    modifier exclusive() {
        require(!busy, "reentrant");
        busy = true;
        _;
        busy = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function sweep(address payable to) external onlyOwner {
        require(to != address(0), "zero");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "sweep failed");
    }

    function setPayToken(address t) external onlyOwner {
        require(t != address(0), "zero");
        rewardToken = IERC20Like(t);
    }

    function claimTokens(uint256 amount) external {
        require(tokenCredit[msg.sender] >= amount, "not enough");
        tokenCredit[msg.sender] -= amount;
        require(rewardToken.transfer(msg.sender, amount), "transfer failed");
    }

    function weekdayIndex() external view returns (uint256) {
        // Chi de HIEN THI ngay trong tuan; khong dung lam ngau nhien, tien hay quyen.
        // slither-disable-next-line weak-prng
        return (block.timestamp / 1 days + 4) % 7;
    }

    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    function depositSafe() external payable exclusive {
        parked[msg.sender] += msg.value;
    }

    function exitSafe() external exclusive {
        uint256 a = parked[msg.sender];
        parked[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: a}("");
        require(ok, "send failed");
    }
}
