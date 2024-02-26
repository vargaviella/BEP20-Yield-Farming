// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // Token used for yield farming
    IERC20 public token;

    // Mapping of user balances
    mapping(address => uint256) public stakingBalance;
    // Mapping of staking start time
    mapping(address => uint256) public startTime;

    // Constants for APR calculation
    uint256 public constant APR = 1000; // 10% APR
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(string memory _name, string memory _symbol, address _tokenAddress) ERC20(_name, _symbol) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
    }

    // Function to stake tokens
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        token.safeTransferFrom(msg.sender, address(this), _amount);
        
        stakingBalance[msg.sender] += _amount;
        startTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    // Function to unstake tokens
    function withdraw() external {
        uint256 balance = stakingBalance[msg.sender];
        require(balance > 0, "Nothing to withdraw");

        uint256 timeElapsed = block.timestamp - startTime[msg.sender];
        uint256 yield = (balance * APR * timeElapsed) / SECONDS_PER_YEAR;
        
        stakingBalance[msg.sender] = 0;
        startTime[msg.sender] = 0;

        _mint(msg.sender, yield);
        token.safeTransfer(msg.sender, balance);

        emit Withdrawn(msg.sender, balance);
    }
}
