// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IDelegatedMinter {
    function delegateMint(address account, uint256 amount) external;
}