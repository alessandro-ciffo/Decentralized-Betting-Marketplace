pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol"; 
import "@chainlink/contracts/src/v0.5/ChainlinkClient.sol";

// If you want to deploy the contract in the JavaVM you have to:
// - set eventFinished= true (Line 34) 
// - comment out setPublicChainlinkToken(); in constructor (Line 75)

contract Bet is ChainlinkClient {

    using SafeMath for uint256;
    using Chainlink for Chainlink.Request;

    // Chainlink variables
    // oracle, jobID, fee are details given by the operator choosen for this job
    address oracle = 0x1b666ad0d20bC4F35f218120d7ed1e2df60627cC;
    bytes32 jobId = "2d3cc1fdfede46a0830bbbf5c0de2528";
    uint fee = 1;

    string teams;
    uint8 betScenario;
    uint odds;
    uint sellerMaxAmount; // in Wei, 1 Ether = 1e18 Wei 
    bool covered;
    uint maxAmountBuyable;
    bool public buyersWon;
    bool public betSettled = false;

    uint public outcome;
    bool public eventFinished = false;

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
    mapping (address => uint) public priceAsked; // maps buyers to the price they ask to resell their bet's position
    mapping (address => uint) public winners; // mapping of winners and amount available for withdrawal

    event NewBet(string teams, uint betScenario, uint odds, uint sellerMaxAmount, bool covered, uint maxAmountBuyable);
    event BetCovered(bool covered);
    event BetSold(address buyer, uint value);
    event BetResold(address from, address to, uint price, uint amount);
    event BetPaidOut(address to, uint amount);
    event RequestEventOutcomeFulfilled(bytes32 indexed requestID, uint256 eventOutcome);

    constructor (string memory _teams, uint8 _betScenario, uint _odds, uint _sellerMaxAmount) public payable {
        teams = _teams;
        betScenario = _betScenario;
        odds = _odds;
        sellerMaxAmount = _sellerMaxAmount;
        maxAmountBuyable = sellerMaxAmount.div(odds);

        // operators can be found on https://market.link/search/jobs?query=Get%20%3E%20Uint256
        setPublicChainlinkToken();
        fee = fee.div(20);
        
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
        buyers.push(msg.sender); 
        maxAmountBuyable = maxAmountBuyable.sub(msg.value);
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

    function getEventOutcome() public returns (bytes32 requestId) {
        // this function calls the oracle to retrieve the match outcome (home team won, draw, away team won)
        // before calling this function Link (the currency of the oracle-provider used here) has
        // to be transfered from your Metamask wallet to the contract
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // Set the URL to perform the GET request on
        string memory url = string(abi.encodePacked("http://big-lizard-50.loca.lt/api/v1/matches/?name=", teams));
        request.add("get", url);
        request.add("path", "CONTRACT.outcome");
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _outcome) public recordChainlinkFulfillment(_requestId) {
        // callback function of the oracle
        outcome = _outcome;
        eventFinished = true;
    }


    function checkOutcome() public view returns(uint) {
        // check outcome of the event
        return outcome;
    }

    function settleBet() public {
        // function to be called after bet is finished. 
        // buyers win if the outcome of the event occurs, otherwise sellers win
        require(eventFinished);
        if (outcome == betScenario) {
            for(uint256 i; i < buyers.length; i++) {
                winners[buyers[i]] = outstandingBetsBuyers[buyers[i]];
            }
            buyersWon = true;
        } else {
            for(uint256 i; i < sellers.length; i++) {
                winners[sellers[i]] = outstandingBetsSeller[sellers[i]];
            }
            buyersWon = false;
        }

        // If Bet hasnt been bought up completly --> Sellers should get their stake back
        // Sellers are also added to the winners mapping with value: Percentual Stake * maxAmountBuyable
        if (maxAmountBuyable > 0) {
            for(uint256 i; i < sellers.length; i++) {
                uint percentualStake = (outstandingBetsSeller[sellers[i]].mul(odds).div(sellerMaxAmount));
                winners[sellers[i]] = (percentualStake.mul(maxAmountBuyable)).mul(odds);
            }
        }

        betSettled = true;      
    }

    function withdrawGains() public payable{
        // function that winners can call to withdraw their gains
        require(betSettled == true,"The bet has to be settled first!");
        address payable to = msg.sender;
        // IF-Event: Bet hasnt been bought up completly --> Sellers should get their stake back 
        if (maxAmountBuyable > 0) {
            to.transfer(winners[msg.sender]);
            
        }
        // distinguish between buyer and seller cases
        if (buyersWon == true) {
            to.transfer(winners[msg.sender].add(winners[msg.sender].div(odds))); // value won + stake is paid out
        } else {
            to.transfer(winners[msg.sender].add(winners[msg.sender].mul(odds))); // value won + stake is paid out
        }
        delete winners[to];
        emit BetPaidOut(msg.sender, winners[msg.sender]);
    
    }


    // Bet reselling 
    
    
    function putPositionForSale(uint _price, uint _betAmount, bool _isBuyer) public {
    // function to put position on sale 
        
        // component makes sure that one can only put a amount(=potential payoff of position) of the bet for sale which the person actually owns
        if (_isBuyer == true) { 
            require(_betAmount <= outstandingBetsBuyers[msg.sender]);
        } else {
            require(_betAmount <=  outstandingBetsSeller[msg.sender]);
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
            buyers.push(msg.sender);
            address payable to = _reseller; // amount is getting paid to reseller
            to.transfer(msg.value);
        } else {
            outstandingBetsSeller[_reseller] = outstandingBetsSeller[_reseller].sub(positionsForSale[_reseller].amount);
            outstandingBetsSeller[msg.sender] = outstandingBetsSeller[msg.sender].add(positionsForSale[_reseller].amount);
            sellers.push(msg.sender);
            address payable to = _reseller; // amount is getting paid to reseller
            to.transfer(msg.value);
        }

        isForSale[msg.sender] = false; // rebuyer's position is not for sale by default
        isForSale[_reseller] = false;
        emit BetResold(_reseller, msg.sender, msg.value, positionsForSale[_reseller].amount);

        // offered position should be deleted
        delete positionsForSale[_reseller];
    }
    

}
