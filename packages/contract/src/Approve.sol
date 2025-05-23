// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Contract is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Token {
        USDC,
        USDT
    }

    struct Payment {
        uint256 amount;
        Token token;
        string appName;
    }

    address public immutable usdc;
    address public immutable usdt;

    mapping(address => Payment[]) private userPayments;
    mapping(address => mapping(Token => uint256)) private users;

    /**
     * @notice Get the token balance for a specific address
     * @param _user Address of the user
     * @param _token Token enum (USDC, USDT, or CUSTOM_TOKEN)
     * @return uint256 Balance of the specified token for the user
     */
    function getBalance(
        address _user,
        Token _token
    ) external view returns (uint256) {
        return users[_user][_token];
    }
    mapping(Token => uint256) public totalFeesCollected;

    event TokensTransferred(
        address indexed from,
        address indexed to,
        Token indexed token,
        uint256 amount,
        string appName
    );

    event TokensWithdrawn(
        address indexed recipient,
        Token indexed token,
        uint256 indexed amount
    );

    constructor(address _usdc, address _usdt) Ownable(msg.sender) {
        require(
            _usdc != address(0) && _usdt != address(0),
            "Invalid token address"
        );
        usdc = _usdc;
        usdt = _usdt;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function transferFrom(
        Token _token,
        string calldata _appName,
        uint256 _amount,
        address _recipient
    ) external payable whenNotPaused nonReentrant {
        require(_amount > 0, "Invalid amount");
        require(_recipient != address(0), "Invalid recipient");
        address tokenAddr = _getTokenAddress(_token);
        IERC20(tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);

        userPayments[_recipient].push(
            Payment({amount: _amount, token: _token, appName: _appName})
        );

        users[_recipient][_token] += _amount;

        emit TokensTransferred(
            msg.sender,
            _recipient,
            _token,
            _amount,
            _appName
        );
    }

    function withdraw(Token _token) external nonReentrant {
        uint256 amount = users[msg.sender][_token];
        require(amount > 0, "No tokens to withdraw");
        users[msg.sender][_token] = 0;
        address tokenAddr = _getTokenAddress(_token);
        IERC20(tokenAddr).safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(msg.sender, _token, amount);
    }

    function _getTokenAddress(Token token) internal view returns (address) {
        if (token == Token.USDC) return usdc;
        if (token == Token.USDT) return usdt;
        revert("Unsupported token");
    }

    function getPayments(
        address _user
    ) external view returns (Payment[] memory) {
        return userPayments[_user];
    }
}
