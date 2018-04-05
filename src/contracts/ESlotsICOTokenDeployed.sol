pragma solidity ^0.4.2;

import "./ESlotsICOToken.sol";

contract ESlotsICOTokenDeployed {

    // address of token contract (for dividend payments)
    address internal tokenContractAddress;
    ESlotsICOToken icoContract;

    function ESlotsICOTokenDeployed(address tokenContract) public {
        require(tokenContract != address(0));
        tokenContractAddress = tokenContract;
        icoContract = ESlotsICOToken(tokenContractAddress);
    }
}