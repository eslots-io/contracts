pragma solidity ^0.4.18;

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/Dividends.sol

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

// File: contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ESlotsICOToken.sol

contract ESlotsICOToken is ERC20, DividendContract {

    string public constant name = "Ethereum Slot Machine Token";
    string public constant symbol = "EST";
    uint8 public constant decimals = 18;

    function maxTokensToSale() public view returns (uint256);
    function availableTokens() public view returns (uint256);
    function completeICO() public;
    function connectCrowdsaleContract(address crowdsaleContract) public;
}

// File: contracts/ESlotsICOTokenDeployed.sol

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

// File: contracts/SlotMachineGambling.sol

contract SlotMachineGambling is ESlotsICOTokenDeployed {

    // Owner's address
    address public owner;

    // Hardcoded address of super owner (for security reasons)
    address internal super_owner = 0xCbEB7496186D4b570B8e7A66cC78892A25909DD5;

    // Hardcoded address of slot machine backend (for security reasons)
    address internal backendAddress = 0xfc14521471bba1884B4b6D0B7D60A22e3526998D;

    uint32 maxCoins; // player's maximum balance
    uint256 coinPrice; // 1 Coin for 0.001 ETH
    uint256 blocksBeforeWithdraw; // minimum amount of blocks to confirm the game before withdrawal. The game should be stopped.
    uint32 maxSpinsAtOnce; // maximum spins can be save at once

    uint256 minBankroll;

    uint256 gasPerSpin;
    uint256 gasPrice;
    uint256 gasLimit;

    uint256 stopGameGasConsumption;

    uint32[5][2] win3ReelsTable;

    struct Player {
        uint32 coins; // amount of collected coins
        bool isGameInProcess;
        uint256 endGameBlock; // number of the block when coins has been collected
        uint256 gasCollected;
        uint256 gasSpent;
    }

    mapping (address => Player) public players;

    function SlotMachineGambling(address tokenContract) public
    ESlotsICOTokenDeployed(tokenContract)
    {
        owner = msg.sender;
        coinPrice = 1000000000000000; // 1 Coin for 0.001 ETH
        maxCoins = 1000; // maximum amount of coins player can buy
        blocksBeforeWithdraw = 2;
        maxSpinsAtOnce = 100;
        gasPerSpin = 21000 + 24503; // amount of gas used to store one single spin
        gasLimit = 300000;
        gasPrice = 40000000000; // 40GWei - default gas price
        stopGameGasConsumption = 61850;

        minBankroll = 10000000000000000000; //10 Ether

        //One coin spin
        win3ReelsTable[0][0] = 200;// 7 bars in line
        win3ReelsTable[0][1] = 50;// 5 bars in line
        win3ReelsTable[0][2] = 10;// 3 bars in line
        win3ReelsTable[0][3] = 1;// blanks in line
        win3ReelsTable[0][4] = 5;// only bars in line
        //double coin spin
        win3ReelsTable[1][0] = 1000;// 7 bars in line
        win3ReelsTable[1][1] = 150;// 5 bars in line
        win3ReelsTable[1][2] = 20;// 3 bars in line
        win3ReelsTable[1][3] = 2;// blanks in line
        win3ReelsTable[1][4] = 10;// only bars in line

    }

    // Modifier for owner's functions of the contract
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == super_owner);
        _;
    }

    // Modifier for super-owner's functions of the contract
    modifier onlySuperOwner {
        require(msg.sender == super_owner);
        _;
    }

    // Modifier for gambling backends's functions of the contract
    modifier onlyBackend {
        require(msg.sender == backendAddress);
        _;
    }

    // Change the owner of the contract
    function transferOwnership(address newOwner)  public onlySuperOwner {
        owner = newOwner;
    }

    function setCoinPrice(uint256 newPrice)  public onlyOwner {
        coinPrice = newPrice;
    }

    function setMinBankroll(uint256 newAmount)  public onlyOwner {
        minBankroll = newAmount;
    }

    function setGasLimit(uint256 newAmount)  public onlyOwner {
        gasLimit = newAmount;
    }

    function setGasDefaultPrice(uint256 newAmount)  public onlyOwner {
        gasPrice = newAmount;
    }

    function setBackendAddress(address newAddress)  public onlyOwner {
        backendAddress = newAddress;
    }

    function getSpinCost() public constant returns(uint256) {
        return gasPerSpin*gasPrice;
    }

    function getCoinPriceWithGas() public constant returns(uint256) {
        return coinPrice + getSpinCost();
    }

    function getCoinPrice() public constant returns(uint256) {
        return coinPrice;
    }

    function() public payable { }

    function payDividends(uint256 amount) payable public onlyBackend {
        require(amount > 0 && this.balance > amount);
        uint256 gas = gasLimit;
        uint256 gasValue = gas*tx.gasprice;
        uint256 real_amount = amount - gasValue;
        uint256 bank = this.balance - real_amount;
        require(bank > 0);
        icoContract.payDividends.value(real_amount).gas(gas)();
    }

    //do not call this function directly - you may loose your ethers if miscount is detected
    function startGame() payable public {
        Player storage player = players[msg.sender];
        uint256 coinPriceWithGas = getCoinPriceWithGas();
        require(player.coins > 0 || msg.value >= coinPriceWithGas);
        if(msg.value > 0) {
            uint256 coins = player.coins;
            if(msg.value >= coinPrice) {
                uint256 coinsIncrease = msg.value/coinPriceWithGas;
                coins += coinsIncrease;
                //send gas to the backend contract
                uint256 gasCollected = coinsIncrease*getSpinCost();
                backendAddress.transfer(gasCollected);
                player.gasCollected += gasCollected;
            }
            if(coins > maxCoins ) {
                coins = maxCoins;
            }
            player.coins = uint32(coins);
        }
        player.isGameInProcess = true;
    }

    function getWithdrawAmount(address playerAddress) public constant returns(uint256) {
        Player storage player = players[playerAddress];
        uint256 amount = player.coins*coinPrice;
        if(player.gasCollected > player.gasSpent) {
            amount += player.gasCollected - player.gasSpent;
        }
        return amount;
    }

    //do not call this function directly - you may loose your ethers if miscount detected
    function withdraw() public returns (bool){
        Player storage player = players[msg.sender];
        require(player.isGameInProcess == false);
        //require(block.number > player.endGameBlock && (block.number - player.endGameBlock) >= blocksBeforeWithdraw);
        uint256 amount = getWithdrawAmount(msg.sender);
        if (amount > 0) {
            player.coins = 0;
            player.gasSpent = 0;
            player.gasCollected = 0;
            msg.sender.transfer(amount);
            return true;
        }
        return false;
    }

    function coins(address playerAddress) public constant returns(uint32) {
        return players[playerAddress].coins;
    }

    function stopGame(address playerAddress) public onlyBackend {
        //uint startGas = msg.gas;
        Player storage player = players[playerAddress];
        require(player.isGameInProcess);
        player.isGameInProcess = false;
        player.endGameBlock = block.number;
        //5960 gas used to save gasSpent
        //player.gasSpent += (startGas - msg.gas + 5960)*tx.gasprice;
        player.gasSpent += stopGameGasConsumption*tx.gasprice;
    }

    //for development only - remove in release
    //todo remove
    function cleanup() public onlyBackend {
        backendAddress.transfer(this.balance);
    }

    function spin3(address playerAddress, uint8[] reels) public onlyBackend {
        uint startGas = msg.gas;
        Player storage player = players[playerAddress];
        require(player.isGameInProcess && player.coins > 0);
        uint spins = maxSpinsAtOnce;
        if(reels.length < spins) {
            spins = reels.length;
        }
        uint i = 0;
        uint32 playerCoins = player.coins;
        for(i = 0; i < spins; i++) {
            uint8 rls = reels[i];
            uint8 multiplier = rls & 0x03;
            require(multiplier == 1 || multiplier == 2);
            require(playerCoins >= multiplier);
            playerCoins -= multiplier;
            uint8 r1 = (rls >> 2) & 0x03;
            uint8 r2 = (rls >> 4) & 0x03;
            uint8 r3 = (rls >> 6) & 0x03;
            uint8 line = 255;
            if(r1 == r2 && r2 == r3) {
                line = r1;
            } else if (r1 < 3 && r2 < 3 && r3 < 3) {
                line = 4;
            }
            if(line < 5) {
                playerCoins += win3ReelsTable[multiplier - 1][line];
            }
        }
        player.coins = playerCoins;
        //5960 gas used for save gasSpent
        //25472 gas transation cost with one spin
        //198 gas for each next spin
        uint256 gasUsed = startGas - msg.gas+5960+23335+198*(reels.length-1);
        player.gasSpent += gasUsed*tx.gasprice;//(gas to this line + gas used to store spent gas + transactional gas)
    }
}
