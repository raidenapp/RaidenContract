//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RaidenToken is ERC20 {
    constructor() ERC20("Raiden Token", "RDNT") {
        _mint(msg.sender, 500000000 ether);
    }
}