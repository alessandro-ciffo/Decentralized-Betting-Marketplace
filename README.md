 # Decentralized-Betting-Marketplace
A smart contract through which people can buy and sell bets.

## 1. Abstract
The aim of the project is to develop a platform that enables individuals to interact through bets, which can be bought and sold through a smart contract, in order to achieve a **decentralized betting marketplace**.

## 2. Introduction
In order to clarify the topic, we will introduce the betting exchange marketplace. <br>
A bet is an amount of money that you risk on the result of an uncertain event, which is associated to some odds. Odds indicate the amount to be won if the event occurs.
The odds are set by bookmakers, who accepts bets from consumers and repays them in case the outcome of the bet occurs.
Since bookmakers always have to make a profit regardless of the outcome of the event, they will apply a margin to the odds, which results in worse odds for consumers and hence smaller payoffs.

Betting exchanges, however, were created to provide better odds to consumers. A betting exchange works like a stock exchange, in which instead of stocks people trade bets. Odds are established by the intersection of supply and demand, which results in better odds for consumer, and hence *higher payoffs on winning bets*.
However, exchange acts as an intermediary between buyers and sellers, which earns a 5% commission on the winning bet, in order to make sure that the loser will repay the counterpart. By disposal of third parties, it is possible to cut commision fees and increase the profit of the players.

### 2.1 Example
1. Bob creates a smart contract to sell the bet with the following parameters:
    - *Event*: Milan wins against Juventus
    - *Odds*: 2.5
    - *Maximum amount covered*: 100€ \
       (which indicates the maximum amount Bob is willing to repay
       <sup>100€</sup>&frasl;<sub>2.5</sub> = 40 tokens
    - Now Bob holds 100% of the ownership of the seller's bet, which corresponds to 40 Buyer-token
2. Alice buys the bet for 20€, which means she could potentially win 20€ * 2.5 = 50 €
    - Alice buys 20 Buyer-token from Bob, earning 50% ownership of the Buyers-bet
3. Mark buys the bet for 20€
    - Mark has now the other 50% ownership of Bob

- if **Milan wins** (Alice and Mark win, Bob loses), then Alice and Mark receive the value corresponding to their entry in the Outstanding bets dictionary (50€ each in this case), which is transferred to their wallets. Bob loses the 100€ he deposited in the beginning.
- if **Milan DOES NOT win** ((Alice and Mark loses, Bob wins), Alice and Mark each hold 50% of the Buyer-Tokens representing each 50% ownership of the Buyers-bet. Based on this, each of them receives 50% of the Buyers-payoff i.e. 50€ each.

### 2.2 Example
4. Let's assume that before the bet ends, Alice decides to put her stake of the bet on sale, specificing how much she wants to sell the bet for, which we'll call *price*.
5. Mario, who is interested in buying Alice's stake, buys the already placed bet.
6. Tokens are transferred from Alice's wallet to Mario's wallet, and the money is transferred from Mario's wallet to Alice's.
7. The price transferred is a matter of negotiation between Alice and Mario, since odds may have been changed compared to the initial state.

## 3. Smart Contract

## 4. Front-End
One of blockchain’s disadvantages is its *abstractness*, which constitutes our primary challenge in helping customers participating in the decentralized betting exchange marketplace, even if they know little about FinTech.

In order to make the smart contract user-friendly, we implemented it inside a local front-end web application accessible through the execution of a python script. The platform is connected to the [Kovan Test Network](https://kovan.etherscan.io/), allowing users to interact with the smart contract through some [Metamask](https://metamask.io/) addresses we previously created and supplied with Ethers, as an exhibit of our prototype. 
Once the connection is established, the user can access the platform by following the link provided, which will access the simulation of a marketplace by buying and selling bets with the registered accounts. 
When the match ends, the user can settle the bet so that the money is transferred to the winners’ accounts. Each transaction that is sent to the blockchain is also stored inside local SQL databases to keep track of the changes. 
All the features of the smart contract (except for the possibility of reselling a position) and the validity checks are implemented in the web app: bets are created by the sellers, who cannot buy their own bets, and there can be more than one buyer for each bet so that the betting price will be split.

The web app entails few advantages: it is easier for everyday consumers to choose inter bets thanks to the user-friendly graphical interface, the error and warning messages on the terminal are much clearer than the ones raised in Remix, and the automatization of the settling of all the bets. If there are no buyers, the seller’s deposited Ether amount will be automatically returned to his/her wallet in full. 
However, there is only one minor downside: waiting times increase. As we are working on an actual blockchain, processing each transaction in the new architecture takes more time with respect to Remix. 
