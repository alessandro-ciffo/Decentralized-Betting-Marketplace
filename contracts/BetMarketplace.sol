pragma solidity ^0.5.0;



import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol"; 



contract BetFactory {
    
    Bet[] bets;
    
    function createBet(string memory _teams, uint8 _betScenario, uint _odds, uint _sellerMaxAmount) public {
        Bet bet = new Bet(_teams, _betScenario, _odds, _sellerMaxAmount);
        bets.push(bet);
    }

}



contract Bet {

    using SafeMath for uint256;
    
    string teams;
    uint8 betScenario;
    uint odds;
    uint sellerMaxAmount; // in Wei, 1 Ether = 1e18 Wei 
    bool covered;
    uint maxAmountBuyable;

    mapping(address => uint) public outstandingBets;
    mapping(address => bool) public positionsForSale; // a buyer's entry in the mapping is set to true if they want to resell the bet
    
    event NewBet(string teams, uint betScenario, uint odds, uint sellerMaxAmount, bool covered, uint maxAmountBuyable);
    event BetCovered(bool covered);
    event BetSold(address buyer, uint value);

    constructor (string memory _teams, uint8 _betScenario, uint _odds, uint _sellerMaxAmount) public payable {
        teams = _teams;
        betScenario = _betScenario;
        odds = _odds;
        sellerMaxAmount = _sellerMaxAmount.mul(1e15);
        maxAmountBuyable = sellerMaxAmount.div(odds);
        require(msg.value == sellerMaxAmount); // seller must deposit _sellerMaxAmount inside the contract
        emit NewBet(teams, betScenario, odds, sellerMaxAmount, covered, maxAmountBuyable);
    }

    function buyBet() public payable {
        // buy a stake in the bet for msg.value, meaning the caller can potentially win msg.value * odds
        require(msg.value <= maxAmountBuyable);
        outstandingBets[msg.sender] = outstandingBets[msg.sender].add(msg.value.mul(odds));  // Update buyers entry in the mapping with the amount they could win
        positionsForSale[msg.sender] = false; // buyer's position is not for sale by default
        maxAmountBuyable = maxAmountBuyable.sub(msg.value);
        emit BetSold(msg.sender, msg.value);
    }

    function checkMaxAmountBuyable() public view returns(uint) {
        // maxAmountBuyable in Ether
        return maxAmountBuyable; 
    }

    function checkBuyerPosition() public view returns(uint) {
        // return caller's stake (what they could potentially win) of the bet - only for buyers
        return outstandingBets[msg.sender];
    }

    function checkEventOutcome() public pure {
        // TODO: check the outcome of the event (home team won, draw, home team lost) using external data 
    }

    function settleBet() public pure {
        // TODO: redistribute money according to the outcome of the event
    }


    // Bet reselling 
    
    mapping (address => uint) priceAsked; // maps buyers to the price they ask to resell their bet's position

    event BetResold(address from, address to, uint price);

    function putPositionForSale(address _reseller, uint _price) public {
        require(msg.sender == _reseller); // only reseller can put their position for sale
        uint price = _price * 1e15; // convert price from Finney to Wei
        priceAsked[msg.sender] = price; // update mapping of prices asked by resellers
        positionsForSale[msg.sender] = true; // position is now for sale
    }

    function buyResellerPosition(address payable _reseller) public payable {
        require(positionsForSale[_reseller] == true);
        require(msg.value == priceAsked[_reseller]);
        uint resellerProfit = msg.value - (outstandingBets[_reseller].div(odds)); // price asked - original price 
        _reseller.transfer(resellerProfit); // reseller is payed
        outstandingBets[msg.sender] = outstandingBets[_reseller]; // rebuyer now owns reseller's stake
        positionsForSale[msg.sender] = false; // rebuyer's position is not for sale by default
        emit BetResold(_reseller, msg.sender, priceAsked[_reseller]);
        // reseller is now out of the bet
        delete positionsForSale[_reseller];
        delete outstandingBets[_reseller];
        delete priceAsked[_reseller];
    }

    // TODO:
    // - Implement oracle to get data about event outcome
    // - Implement function to settle payments at the end of the event
    // - So far, the seller (the one who creates the contract) cannot sell the bet. Find a way to allow it
    // - So far, reseller (buyer who decide to resell their position) can only resell the entire position. We should allow them 
    //   to sell just a portion of it if they want 

}



