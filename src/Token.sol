// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "./IDelegatedMinter.sol";

contract MyToken is ERC20Burnable, Ownable, IDelegatedMinter {
    address private cctpMinter;

    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 1000 ether);
    }

    //function mint(address to, uint256 amount) public onlyOwner {
    //    _mint(to, amount);
    //}

    // The following are work arounds until the open zep refactoring is 
    // complete for ERC20 mintable

    function addCCTPMinter(address minter) public onlyOwner {
        cctpMinter = minter;
    }

    function delegateMint(address to, uint256 amount) public {
        require(msg.sender == cctpMinter);
        _mint(to,amount);
    }

}