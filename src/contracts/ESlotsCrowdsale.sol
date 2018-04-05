pragma solidity ^0.4.2;

import "./math/SafeMath.sol";
import "./ownership/Ownable.sol";
import "./ESlotsICOTokenDeployed.sol";


contract ESlotsCrowdsale is Ownable, ESlotsICOTokenDeployed {
    using SafeMath for uint256;

    enum State { PrivatePreSale, PreSale, ActiveICO, ICOComplete }
    State public state;

    // start and end timestamps for dates when investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address for funds collecting
    address public wallet = 0x7b97B31E12f7d029769c53cB91c83d29611A4F7A;

    // how many token units a buyer gets per wei
    uint256 public rate = 1000; //base price: 1 EST token costs 0.001 Ether

    // amount of raised money in wei
    uint256 public weiRaised;

    mapping (address => uint256) public privateInvestors;

    /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function ESlotsCrowdsale(address tokenContract) public
    ESlotsICOTokenDeployed(tokenContract)
    {
        state = State.PrivatePreSale;
        startTime = 0;
        endTime = 0;
        weiRaised = 0;
        //do not forget to call
        //icoContract.connectCrowdsaleContract(this);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());


        uint256 weiAmount = msg.value;
        // calculate amount of tokens to be created
        uint256 tokens = getTokenAmount(weiAmount);
        uint256 av_tokens = icoContract.availableTokens();
        require(av_tokens >= tokens);
        if(state == State.PrivatePreSale) {
            require(privateInvestors[beneficiary] > 0);
            //restrict sales in private period
            if(privateInvestors[beneficiary] < tokens) {
                tokens = privateInvestors[beneficiary];
            }
        }
            // update state
        weiRaised = weiRaised.add(weiAmount);
        //we can get only 75% to development, 25% will be unlocked after 2 months to fill out casino contract bankroll
        wallet.transfer(percents(weiAmount, 75));
        icoContract.transferFrom(owner, beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function addPrivateInvestor(address beneficiary, uint256 value) public onlyOwner {
        require(state == State.PrivatePreSale);
        privateInvestors[beneficiary] = privateInvestors[beneficiary].add(value);
    }

    function startPreSale() public onlyOwner {
        require(state == State.PrivatePreSale);
        state = State.PreSale;
    }

    function startICO() public onlyOwner {
        require(state == State.PreSale);
        state = State.ActiveICO;
        startTime = now;
        endTime = startTime + 7 weeks;
    }

    function stopICO() public onlyOwner {
        require(state == State.ActiveICO);
        require(icoContract.availableTokens() == 0 || (endTime > 0 && now >= endTime));
        require(weiRaised > 0);
        state = State.ICOComplete;
        endTime = now;
    }

    // Allow getting slots bankroll after 60 days only
    function cleanup() public onlyOwner {
        require(state == State.ICOComplete);
        require(now >= (endTime + 60 days));
        wallet.transfer(this.balance);
    }

    // @return true if crowdsale ended
    function hasEnded() public view returns (bool) {
        return state == State.ICOComplete || icoContract.availableTokens() == 0 || (endTime > 0 && now >= endTime);
    }

    // Calculate amount of tokens depending on crowdsale phase and time
    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        uint256 totalTokens = weiAmount.mul(rate);
        uint256 bonus = getLargeAmountBonus(weiAmount);
        if(state == State.PrivatePreSale ||  state == State.PreSale) {
            //PreSale has 50% bonus!
            bonus = bonus.add(50);
        } else if(state == State.ActiveICO) {
            if((now - startTime) < 1 weeks) {
                //30% first week
                bonus = bonus.add(30);
            } else if((now - startTime) < 3 weeks) {
                //15% second and third weeks
                bonus = bonus.add(15);
            }
        }
        return addPercents(totalTokens, bonus);
    }

    function addPercents(uint256 amount, uint256 percent) internal pure returns(uint256) {
        if(percent == 0) return amount;
        return amount.add(percents(amount, percent));
    }

    function percents(uint256 amount, uint256 percent) internal pure returns(uint256) {
        if(percent == 0) return 0;
        return amount.mul(percent).div(100);
    }

    function getLargeAmountBonus(uint256 weiAmount) internal pure returns(uint256) {
        if(weiAmount >= 1000 ether) {
            return 50;
        }
        if(weiAmount >= 500 ether) {
            return 30;
        }
        if(weiAmount >= 100 ether) {
            return 15;
        }
        if(weiAmount >= 50 ether) {
            return 10;
        }
        if(weiAmount >= 10 ether) {
            return 5;
        }
       return 0;
    }

    // return true if the transaction is suitable for buying tokens
    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return hasEnded() == false && nonZeroPurchase;
    }

}