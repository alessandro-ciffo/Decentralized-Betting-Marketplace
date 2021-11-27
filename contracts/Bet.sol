pragma solidity >=0.5.0 <0.6.0;

contract Bet {
    

    uint buyerMaxAmount;
    uint buyerAmountLeft;
    address buyerAddress;
    
    uint eventId;
    uint8 betScenario;
    uint odds;
    uint sellerMaxAmount;
    uint sellerAmountLeft;

    address[] public buyers;
    address[] public sellers;
    mapping(address => uint256) public balanceOfSeller;
    mapping(address => uint256) public balanceOfBuyer;




    constructor(uint _eventId, uint8 _betScenario, uint _odds, uint _sellerMaxAmount) public {

        eventId = _eventId;
        betScenario = _betScenario;
        odds = _odds;
        sellerMaxAmount = _sellerMaxAmount;
        sellerAmountLeft = _sellerMaxAmount;
        buyerMaxAmount = _sellerMaxAmount/ _odds;
        buyerAmountLeft = buyerMaxAmount;
    }

    function placeStakeSeller(uint _amount) public payable {
        require(msg.value == _amount);
        require(_amount <= sellerAmountLeft);
        balanceOfSeller[msg.sender] += _amount;
        sellers.push(msg.sender);
        sellerAmountLeft -= _amount;
    }

    function placeStakeBuyer(uint _amount) public payable {
        require(msg.value == _amount);
        require(_amount <= buyerAmountLeft);
        balanceOfBuyer[msg.sender] += _amount;
        buyerAmountLeft -= _amount;
    }

}
