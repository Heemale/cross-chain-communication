// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface mContract {
    function onCrossChainCall(bytes calldata message) external payable;
}