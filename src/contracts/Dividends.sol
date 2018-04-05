pragma solidity ^0.4.18;

import "./math/SafeMath.sol";

contract DividendContract {
  using SafeMath for uint256;
  event Dividends(uint256 round, uint256 value);
  event ClaimDividends(address investor, uint256 value);

  uint256 totalDividendsAmount = 0;
  uint256 totalDividendsRounds = 0;
  uint256 totalUnPayedDividendsAmount = 0;
  mapping(address => uint256) payedDividends;


  function getTotalDividendsAmount() public constant returns (uint256) {
    return totalDividendsAmount;
  }

  function getTotalDividendsRounds() public constant returns (uint256) {
    return totalDividendsRounds;
  }

  function getTotalUnPayedDividendsAmount() public constant returns (uint256) {
    return totalUnPayedDividendsAmount;
  }

  function dividendsAmount(address investor) public constant returns (uint256);
  function claimDividends() payable public;

  function payDividends() payable public {
    require(msg.value > 0);
    totalDividendsAmount = totalDividendsAmount.add(msg.value);
    totalUnPayedDividendsAmount = totalUnPayedDividendsAmount.add(msg.value);
    totalDividendsRounds += 1;
    Dividends(totalDividendsRounds, msg.value);
  }
}