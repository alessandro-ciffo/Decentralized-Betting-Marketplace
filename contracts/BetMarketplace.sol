pragma solidity ^0.5.0;



import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol"; 



contract BetFactory {
    
    Bet[] bets; //shouldn't we define Bet as struct?
    
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

    // facilitates loop over mappings
    address payable[] public buyers;
    address payable[] public sellers;

    //Log of current shareholders of the bet
    mapping(address => uint) public outstandingBetsSeller;
    mapping(address => uint) public outstandingBetsBuyers;
    

    struct BetToSale {   
        uint amount;    // amount of the bet which should be sold
        uint price;     // the price for which this amount should be sold
        bool isBuyer;   // if the bet is offered by a Buyer --> buyer = true
    }
    mapping(address => BetToSale) public positionsForSale; //mapping containing all the bets which are currently for resell
    mapping(address => bool) public isForSale; // a buyer's entry in the mapping is set to true if they want to resell the bet
    mapping (address => uint) priceAsked; // maps buyers to the price they ask to resell their bet's position
    
    event NewBet(string teams, uint betScenario, uint odds, uint sellerMaxAmount, bool covered, uint maxAmountBuyable);
    event BetCovered(bool covered);
    event BetSold(address buyer, uint value);
    event BetSettled(address winner, uint value);
    event BetResold(address from, address to, uint price, uint amount);

    constructor (string memory _teams, uint8 _betScenario, uint _odds, uint _sellerMaxAmount) public payable {
        teams = _teams;
        betScenario = _betScenario;
        odds = _odds;
        sellerMaxAmount = _sellerMaxAmount;
        maxAmountBuyable = sellerMaxAmount.div(odds);
        
        // seller must deposit _sellerMaxAmount inside the contract upon creation
        require(msg.value == sellerMaxAmount); 
        outstandingBetsSeller[msg.sender] += sellerMaxAmount.div(odds);
        sellers.push(msg.sender);
        isForSale[msg.sender] = false;
        emit NewBet(teams, betScenario, odds, sellerMaxAmount, covered, maxAmountBuyable);
    }

    function buyBet() public payable {
        // buy a stake in the bet for msg.value, meaning the caller can potentially win msg.value * odds
        require(msg.value <= maxAmountBuyable);
        outstandingBetsBuyers[msg.sender] = outstandingBetsBuyers[msg.sender].add(msg.value.mul(odds));  // Update buyers entry in the mapping with the amount they could win
        isForSale[msg.sender] = false; // buyer's position is not for sale by default
        maxAmountBuyable = maxAmountBuyable.sub(msg.value);
        buyers.push(msg.sender);
        emit BetSold(msg.sender, msg.value);
    }

    function checkMaxAmountBuyable() public view returns(uint) {
        // maxAmountBuyable in Ether
        return maxAmountBuyable; 
    }

    function checkContractBalance() public view returns(uint) {
        // check balance of the contract
        return address(this).balance;
    }

    function checkBuyerPosition() public view returns(uint) {
        // return caller's stake (what they could potentially win) of the bet - only for buyers
        return outstandingBetsBuyers[msg.sender];
    }

    function checkEventOutcome() public pure {
        // TODO: check the outcome of the event (home team won, draw, home team lost) using external data 
    }


    function settleBet(uint _eventOutcome) public {
        // function to be called after bet is finished
        // discriminates between Sellers and Buyers
        // TODO: connect _eventOutcome to checkEventOutcome() when oracle is done
        // TODO: modify function to just put outstandingBets of the winning side as a new mapping e.g. winners (Loops probably unnecessary now, as well as arrays) 
        // TODO: Winners mapping should contain the addresses of outstanding bet and the valueWon + stake
        // TODO: Account for the case that the bet wasnt completly bought up by the buyer
        if (betScenario == _eventOutcome) { /// if Bet was won by Seller
            uint j =0;
            uint len = sellers.length;
            for (j; j<len; j++) { /// loop over all Sellers of the bet and pay out the won amount relative to their stake
                address payable winnerAddress = sellers[j];
                uint valueWon = outstandingBetsSeller[winnerAddress];

                if (valueWon > 0) {
                    address payable to = winnerAddress; 
                    to.transfer(valueWon.add(valueWon.mul(odds))); //Winner gets his initial stake + stake/odds
                    emit BetSettled(winnerAddress, valueWon);
                } 
            } 
        }

        if (betScenario != _eventOutcome) { /// if Bet was won by Buyer
            uint j =0;
            uint len = buyers.length;
            for (j; j<len; j++) { /// loop over all Buyers of the bet and pay out the won amount relative to their stake
                address payable winnerAddress = buyers[j];
                uint valueWon = outstandingBetsBuyers[winnerAddress];

                if (valueWon > 0) {
                    address payable to = winnerAddress; 
                    to.transfer(valueWon.add(valueWon.div(odds))); //Winner gets his initial stake + stake*odds
                    emit BetSettled(winnerAddress, valueWon);
                } 
            }
        }
    }


    // Bet reselling 
    
    
    function putPositionForSale(address _reseller, uint _price, uint _betAmount, bool _isBuyer) public {
    // function to put position on sale 
        require(msg.sender == _reseller); // only reseller can put their position for sale
        
        // component makes sure that one can only put a amount(=potential payoff of position) of the bet for sale which the person actually owns
        if (_isBuyer == true) { 
            require(_betAmount <= outstandingBetsBuyers[_reseller]);
        } else {
            require(_betAmount <=  outstandingBetsSeller[_reseller]);
        }

        uint price = _price; // convert price from Finney to Wei
        positionsForSale[msg.sender] = BetToSale( _betAmount, price, _isBuyer); // creates a new entry for the bet in mapping with all the necessary information
        isForSale[msg.sender] = true; // position is now for sale
    }

    function buyResellerPosition(address payable _reseller) public payable {
        // function to buy a position which is up for sale
        require(isForSale[_reseller] == true, "Position is currently not up for sale");
        require(msg.value == positionsForSale[_reseller].price, "Message value has to be equal to the price specified in the offer");

        // component substacts sold amount from reseller and add its to buyer of the position in the respective Bet-Log
        if (positionsForSale[_reseller].isBuyer == true) { 
            outstandingBetsBuyers[_reseller] = outstandingBetsBuyers[_reseller].sub(positionsForSale[_reseller].amount);
            outstandingBetsBuyers[msg.sender] = outstandingBetsBuyers[msg.sender].add(positionsForSale[_reseller].amount);
        } else {
            outstandingBetsSeller[_reseller] = outstandingBetsSeller[_reseller].sub(positionsForSale[_reseller].amount);
            outstandingBetsSeller[msg.sender] = outstandingBetsSeller[msg.sender].add(positionsForSale[_reseller].amount);
        }
        
        isForSale[msg.sender] = false; // rebuyer's position is not for sale by default
        isForSale[_reseller] = false;
        emit BetResold(_reseller, msg.sender, msg.value, positionsForSale[_reseller].amount);

        // offered position should be deleted
        delete positionsForSale[_reseller];
    }

    //Comments:
    // - fyi: took the price transformations to Wei out for conviniece, as one can set the value of transaction to Wei in remix
    // - Both Buyers and Sellers can now put their bet for sale (even only partly)
    // - TBD: Now Reoffered Bets can be only bought completly, we could even implement it in a way for it only being bought partly

    // TODO:
    // - Implement oracle to get data about event outcome
    // - Modify function to settle payments at the end of the event
    // (- assure unique addresses in buyers/sellers array)
    // - create withdrawl function
    

}
