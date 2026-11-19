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
        require(msg.sender == owner, "not owner");
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
        to.call{value: address(this).balance}("");
    }

    function plugin(address target, bytes calldata data) external {
        (bool ok, ) = target.delegatecall(data);
        require(ok, "delegatecall failed");
    }

    function setPayToken(address t) external onlyOwner {
        require(t != address(0), "zero");
        rewardToken = IERC20Like(t);
    }

    function claimTokens(uint256 amount) external {
        require(tokenCredit[msg.sender] >= amount, "not enough");
        tokenCredit[msg.sender] -= amount;
        rewardToken.transfer(msg.sender, amount);
    }

    function weekdayIndex() external view returns (uint256) {
        return (block.timestamp / 1 days + 4) % 7;
    }

    function updateOwner(address newOwner) external {
        require(tx.origin == owner, "not owner");
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    function depositSafe() external payable exclusive {
        parked[msg.sender] += msg.value;
    }

    function exitSafe() external exclusive {
        uint256 a = parked[msg.sender];
        (bool ok, ) = msg.sender.call{value: a}("");
        require(ok, "send failed");
        parked[msg.sender] = 0;
    }
}
