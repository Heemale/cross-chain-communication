// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgeLimit {
    function canBridge(address sender, address token, uint256 amountIn) external view returns (bool);
}
