 # Decentralized-Betting-Marketplace
The most flexible way to buy and sell football bets in a decentralized fashion.

## 1. Abstract
The aim of the project is to develop a platform that enables individuals to interact through bets, which can be bought and sold through a smart contract, in order to achieve a **decentralized betting marketplace**.

## 2. Introduction
A bet is an amount of money that you risk on the result of an uncertain event, which is associated to some odds. Odds indicate the amount to be won if the event occurs.

Traditionally, odds are set by bookmakers, who accept bets from consumers and repay them in case the outcome of the bet occurs.
Since bookmakers always have to make a profit regardless of the outcome of the event, they will apply a margin to the odds, which results in worse odds for consumers and hence smaller payoffs.

In order to allow consumers to get more efficient odds, we create a fully decentralized betting marketplace, through which people can buy and sell bets. In particular, each bet is a smart contract created by a bet seller and buyers can buy a stake of the bet. 

Not only is this mechanism more efficient, since odds are set by the intersection of supply and demand, but it is also the most flexible to date. In fact users can buy or sell bets, but they can also resell their position at a different price than the one they paid and they can also buy/sell fractions of their stake. This platform is the only one that allows such a level of flexibility. 

### 2.1 Example
1. Bob creates a smart contract to sell the bet with the following parameters:
    - *Event*: Milan wins against Juventus
    - *Odds*: 2.5
    - *Maximum amount covered*: 100€ \
       (which implies that the maximum amount people can buy of this bet is
       <sup>100€</sup>&frasl;<sub>2.5</sub> = 40€
    - Now Bob holds 100% of the ownership of the seller's bet.
2. Alice buys the bet for 20€, which means she could potentially win 20€ * 2.5 = 50€. 
    - She now has 50% ownership of the Buyers-bet
3. Mark buys the bet for 20€
    - Mark has now the other 50% ownership of Bob

After the end of the football match:
- if **Milan wins** (Alice and Mark win, Bob loses), then Alice and Mark receive the value corresponding to their entry in the Outstanding bets dictionary (50€ each in this case), which they can withdraw from the contract. Bob loses the 100€ he deposited in the beginning.
- if **Milan DOES NOT win** (Alice and Mark loses, Bob wins), Alice and Mark each hold 50% of the Buyer-Tokens representing each 50% ownership of the Buyers-bet. Based on this, each of them receives 50% of the Buyers-payoff i.e. 50€ each.

### 2.2 Example: *Reselling*
4. Let's assume that before the bet ends, Alice decides to put her stake of the bet on sale, specificing how much she wants to sell the bet for, which we'll call *price*.
5. Mario, who is interested in buying Alice's stake, buys the already placed bet.
6. Tokens are transferred from Alice's wallet to Mario's wallet, and the money is transferred from Mario's wallet to Alice's.
7. The price transferred is a matter of negotiation between Alice and Mario, since odds may have been changed compared to the initial state.

## 3. Smart Contract

Let's see how the smart contract works in detail.

### 3.1 Main functionalities

The main buying and selling functions and bet settlements occur inside the **Bet** contract. This contract is created by the seller and is initialized with the following parameters:
- *Teams*: a string of the teams playing during the match (e.g. Juventus-Milan)
- *betScenario*: the encoded result on which the bet is placed. There are 3 possible scenarios: home team wins (0), draw (1) or away team wins (2). Notice: this is the outcome on which the seller is betting *against* (he wins if the outcome does not occur).
- *odds*: how much is paid for each unit of currency bought of the bet.
- *maxAmountBuyable*: how much the seller is willing to repay at most.

In order to create the contract, the seller must deposit *maxAmountBuyable* Wei inside the contract, to make sure he won't run away with the money.

Once the bet contract is created, people can buy a stake of the bet using the **buyBet** function. Using this function, the buyers deposit their stake inside the contract and buy the right to win that stake times the odds.

After the football match ends, a Chainlink oracle is used to retrieve the match outcome from an api we designed. By calling the **getEventOutcome** function, the oracle calls the api and the result of this call populates the variable *outcome*, which stores the true outcome of the match. (Notice: the api was hosted in local and the http address inside the smart contract is a temporary one created using local tunnel. For more information contact the developers.)

Once the outcome of the match is known, the bet can be settled. To do so, the **settleBet** function is called. This function creates a mapping between winners' addresses and the funds they won.

Using the **withdrawGains** function, winners are entitled to withdraw their gains from the smart contract.

### 3.2 Reselling

One of the key strengths of this smart contract is that it allows buyers and sellers to resell their position inside the bet. Stakeholders can sell their position at a price different than the one paid originally. This creates very interesting hedging opportunities. Additionally, buyers and sellers are not required to resell their entire stake. They can resell any desired portion of their position.

To put a position for sale, stakeholders use the **putPositionForSale** function, wheres to buy a position put on resale, they can use the **buyResellerPosition** function.

Settlements and withdrawals work as before.


## 4. Front-End
One of blockchain’s disadvantages is its *abstractness*, which constitutes our primary challenge in helping customers participating in the decentralized betting exchange marketplace, even if they know little about FinTech.

In order to make the smart contract user-friendly, we implemented it inside a local front-end web application accessible through the execution of a python script. The platform is connected to the [Kovan Test Network](https://kovan.etherscan.io/), allowing users to interact with the smart contract through some [Metamask](https://metamask.io/) addresses we previously created and supplied with Ethers, as an exhibit of our prototype. 
Once the connection is established, the user can access the platform by following the link provided, which will access the simulation of a marketplace by buying and selling bets with the registered accounts. 
When the match ends, the user can settle the bet so that the money is transferred to the winners’ accounts. Each transaction that is sent to the blockchain is also stored inside local SQL databases to keep track of the changes. 
All the features of the smart contract (except for the possibility of reselling a position) and the validity checks are implemented in the web app: bets are created by the sellers, who cannot buy their own bets, and there can be more than one buyer for each bet so that the betting price will be split.

The web app entails few advantages: it is easier for everyday consumers to choose inter bets thanks to the user-friendly graphical interface, the error and warning messages on the terminal are much clearer than the ones raised in Remix, and the automatization of the settling of all the bets. If there are no buyers, the seller’s deposited Ether amount will be automatically returned to his/her wallet in full. 
However, there is only one minor downside: waiting times increase. As we are working on an actual blockchain, processing each transaction in the new architecture takes more time with respect to Remix. 

## 5. Appendix: A guide to the repo

The repo is organized as follows:

- The main smart contract is contained inside the **contracts** directory.

- The **api** directory contains the code used to create the api that is called by the oracle inside the contract. It also stores an example json file containing the results of a match.

- The **frontend** directory contains the code necessary to create and run the web app that interacts with the smart contract.
