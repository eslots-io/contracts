pragma solidity ^0.4.2;


import "./token/ERC20/StandardToken.sol";
import "./token/ERC20/BurnableToken.sol";
import "./ownership/Ownable.sol";

import "./ESlotsICOToken.sol";


/**
 * @title eSlotsToken
 * @dev See more info https://eslots.io
 */
contract ESlotsToken is Ownable, StandardToken, ESlotsICOToken {

  event Burn(address indexed burner, uint256 value);

  enum State { ActiveICO, CompletedICO }
  State public state;

  uint256 public constant INITIAL_SUPPLY = 50000000 * (10 ** uint256(decimals));

  address founders = 0x7b97B31E12f7d029769c53cB91c83d29611A4F7A;
  uint256 public constant foundersStake = 10; //10% to founders
  uint256 public constant dividendRoundsBeforeFoundersStakeUnlock = 4;
  uint256 maxFoundersTokens;
  uint256 tokensToSale;

  uint256 transferGASUsage;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  function ESlotsToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    maxFoundersTokens = INITIAL_SUPPLY.mul(foundersStake).div(100);
    tokensToSale = INITIAL_SUPPLY - maxFoundersTokens;
    balances[msg.sender] = tokensToSale;
    Transfer(0x0, msg.sender, balances[msg.sender]);
    state = State.ActiveICO;
    transferGASUsage = 21000;
  }

  function maxTokensToSale() public view returns (uint256) {
    return tokensToSale;
  }

  function availableTokens() public view returns (uint256) {
    return balances[owner];
  }

  function setGasUsage(uint256 newGasUsage) public onlyOwner {
    transferGASUsage = newGasUsage;
  }

  //run it after ESlotsCrowdsale contract is deployed to approve token spending
  function connectCrowdsaleContract(address crowdsaleContract) public onlyOwner {
    approve(crowdsaleContract, balances[owner]);
  }

  //burn unsold tokens
  function completeICO() public onlyOwner {
    require(state == State.ActiveICO);
    state = State.CompletedICO;
    uint256 soldTokens = tokensToSale.sub(balances[owner]);
    uint256 foundersTokens = soldTokens.mul(foundersStake).div(100);
    if(foundersTokens > maxFoundersTokens) {
      //normally we never reach this point
      foundersTokens = maxFoundersTokens;
    }
    BasicToken.transfer(founders, foundersTokens);
    totalSupply_ = soldTokens.add(foundersTokens);
    balances[owner] = 0;
    Burn(msg.sender, INITIAL_SUPPLY.sub(totalSupply_));
  }


  //handle dividends
  function transfer(address _to, uint256 _value) public returns (bool) {
    if(msg.sender == founders) {
      //lock operation with tokens for founders
      require(totalDividendsAmount > 0 && totalDividendsRounds > dividendRoundsBeforeFoundersStakeUnlock);
    }
    //transfer is allowed only then all dividends are claimed
    require(payedDividends[msg.sender] == totalDividendsAmount);
    require(balances[_to] == 0 || payedDividends[_to] == totalDividendsAmount);
    bool res =  BasicToken.transfer(_to, _value);
    if(res && payedDividends[_to] != totalDividendsAmount) {
      payedDividends[_to] = totalDividendsAmount;
    }
    return res;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if(msg.sender == founders) {
      //lock operation with tokens for founders
      require(totalDividendsAmount > 0 && totalDividendsRounds > dividendRoundsBeforeFoundersStakeUnlock);
    }
    //transfer is allowed only then all dividends are claimed
    require(payedDividends[_from] == totalDividendsAmount);
    require(balances[_to] == 0 || payedDividends[_to] == totalDividendsAmount);
    bool res = StandardToken.transferFrom(_from, _to, _value);
    if(res && payedDividends[_to] != totalDividendsAmount) {
      payedDividends[_to] = totalDividendsAmount;
    }
    return res;
  }

  //Dividends

  modifier onlyThenCompletedICO {
    require(state == State.CompletedICO);
    _;
  }

  function dividendsAmount(address investor) public onlyThenCompletedICO constant returns (uint256)  {
    if(totalSupply_ == 0) {return 0;}
    if(balances[investor] == 0) {return 0;}
    if(payedDividends[investor] >= totalDividendsAmount) {return 0;}
    return (totalDividendsAmount - payedDividends[investor]).mul(balances[investor]).div(totalSupply_);
  }

  function claimDividends() payable public onlyThenCompletedICO {
    //gasUsage = 0 because a caller pays for that
    sendDividends(msg.sender, 0);

  }

  //force dividend payments if they hasn't been claimed by token holder before
  function pushDividends(address investor) payable public onlyThenCompletedICO {
    //because we pay for gas
    sendDividends(investor, transferGASUsage.mul(tx.gasprice));
  }

  function sendDividends(address investor, uint256 gasUsage) internal {
    uint256 value = dividendsAmount(investor);
    require(value > gasUsage);
    payedDividends[investor] = totalDividendsAmount;
    totalUnPayedDividendsAmount = totalUnPayedDividendsAmount.sub(value);
    investor.transfer(value.sub(gasUsage));
    ClaimDividends(investor, value);
  }

  function payDividends() payable public onlyThenCompletedICO {
    DividendContract.payDividends();
  }
}
