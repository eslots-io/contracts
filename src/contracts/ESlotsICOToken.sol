pragma solidity ^0.4.2;

import "./token/ERC20/ERC20.sol";
import "./Dividends.sol";

contract ESlotsICOToken is ERC20, DividendContract {

    string public constant name = "Ethereum Slot Machine Token";
    string public constant symbol = "EST";
    uint8 public constant decimals = 18;

    function maxTokensToSale() public view returns (uint256);
    function availableTokens() public view returns (uint256);
    function completeICO() public;
    function connectCrowdsaleContract(address crowdsaleContract) public;
}