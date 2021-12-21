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
       (which indicates the maximum amount Bob is willing to repay.
       $100 \over 2.5 = 40 tokens$
    - Now Bob holds 100% of the ownership of the seller's bet, which corresponds to 40 Buyer-token
2. Alice buys the bet for 20€, which means she could potentially win 20€ * 2.5 = 50 €
    - Alice buys 20 Buyer-token from Bob, earning 50% ownership of the Buyers-bet
3. Mark buys the bet for 20€
    - Mark has now the other 50% ownership of Bob

- if **Milan wins** (Alice and Mark win, Bob loses), then Alice and Mark receive the value corresponding to their entry in the Outstanding bets dictionary (50€ each in this case), which is transferred to their wallets. Bob loses the 100€ he deposited in the beginning.
- if **Milan DOES NOT win** ((Alice and Mark loses, Bob wins), Alice and Mark each hold 50% of the Buyer-Tokens representing each 50% ownership of the Buyers-bet. Based on this each of them receives 50% of the Buyers-payoff i.e. 50 euro each

### 2.2 Example
4. Let's assume that before the bet ends, Alice decides to put her stake of the bet on sale, specificing how much she wants to sell the bet for, which we'll call *price*.
5. Mario, who is interested in buying Alice's stake, buys the already placed bet.
6. Tokens are transferred from Alice's wallet to Mario's wallet, and the money is transferred from Mario's wallet to Alice's
7. The price transferred is a matter of negotiation between Alice and Mario, since odds may have been changed compared to the initial state.
