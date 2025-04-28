// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SystemContract.sol";

contract OnlySystem {

    error OnlySystemContract(string);

    SystemContract public system;

    constructor(address sys) {
        system = SystemContract(sys);
    }

    modifier onlySystem() {
        if (msg.sender != address(system)) {
            revert OnlySystemContract("Only system contract can call this function");
        }
        _;
    }
}