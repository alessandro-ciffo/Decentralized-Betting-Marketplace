''' 
  - IMPORT LIBRARIES
'''

import json
import time
import pandas as pd
from web3 import Web3
from flask import Flask, render_template, request
from flask_sqlalchemy import SQLAlchemy


''' 
  - RETRIEVE USERS STORED IN EXCEL FILE AND PUT THEM IN A DATAFRAME
  - RETRIEVE MATCHES STORED IN EXCEL FILE AND PUT THEM IN 2 DATAFRAMEs
    - one dataframe for the matches, one for the outcomes
  - CREATE IDS FOR THE MATCHES AS "HOMETEAM-AWAYTEAM"
  - ADD IDS TO DATAFRAME
  - CONVERT MATCHES DATAFRAME TO DICT SO THAT IT'S EASIER TO READ WHEN PASSED TO HTML PAGES
'''

users = pd.read_csv("data/users.csv")
matches = pd.read_csv("data/matches.csv")
matches = matches.drop(["outcome"], axis=1)

ids = []
for i in range(len(matches)):
  l = []
  l.append(matches["hometeam"][i])
  l.append(matches["awayteam"][i])
  id_ = '-'.join(l)
  ids.append(id_)

matches.insert(0, "ID", ids, True)
matches = matches.T.to_dict(orient="list")


'''
    - CREATE WEB3 CONNECTION TO KOVAN
    - MATCH EACH USER TO A METAMASK ACCOUNT PREVIOUSLY CREATED AND FILLED WITH ETHERS
    - IMPORT BET CONTRACT'S CONSTRUCTOR VIA ABI AND BYTECODE STORED IN REMIX/.TXT
    - INITIALIZE BETS LIST (list of bets smart contracts objects)
'''

print("Welcome to the Decentralized Bet Marketplace :)")

# create web3 connection to kovan
kovan_address = "https://kovan.infura.io/v3/2863d6bd86694a56a5205cd61cf109a4"
w3 = Web3(Web3.HTTPProvider(kovan_address))

print("Connection established, remember to keep an eye on the terminal to see what's happening.")
print("")
print("Here are the accounts you can use to simulate the exchange: ")
print("")
for i in range(len(users["user"])):
  print("Username: {}".format(users["user"][i]))
  print("Address: {}".format(users["account"][i]))
  balance = w3.eth.getBalance(users["account"][i])
  print("Current balance: {} wei (or {} eth)".format(balance, w3.fromWei(balance, 'ether')))
  print("")
print("Follow the link below to connect to the platform!")

with open('remix/abi.txt', 'r') as file:
    abi_text = file.read()
with open('remix/bytecode.txt', 'r') as file:
    bytecode = file.read()
abi = json.loads(abi_text)

bets_list = []

''' 
  - INITIALIZE FLASK AND SQLALCHEMY:
    - create app
    - define naive secret key (necessary step to proceed)
    - define url for sql database and remove some warnings
  - BUILD BETS DATABASE: EVERY TIME A SELLER ADDS A BET, IT GETS STORED INSIDE DB
  - BUILD BUYERS DATABASE: EVERY TIME A BUYERS BUY (A FRACTION OF) A BET, IT GETS STORED INSIDE DB
  - DEFINE @APP.ROUTES FOR ALL THE HTML PAGES:
    - seller's page retrieves the data from the "create bet form" (with POST method) and 
      stores them in the db only if there are no blanks, then writes on the blockchain.
    - buyers's page retrieves the data from the "choose your bet form" (with POST method) and 
      updates the db only if there are no blanks, if buyer!=seller and if amount<=maxAmountBuyable, 
      then writes on the blockchain.
    - everytime a percentage of a bet is bought, the page updates the maxAmountBuyable cell.
      Once the value goes to zero, the bet immediately becomes no longer visible in the buyer's page.
    - settled page allows for the settle of all the bets:
      if a bet does not have a buyer, money is sent back to the seller through withdrawBetNotMatched();
      if the bet has been matched, the winners are found through settleBet() function;
      all the winners call withdrawGains() function and receive their fraction of the price.
      When the bets are settled, sql database and bets_list are resetted.
  - DELETE AND CRETE DB EVERYTIME THE APP IS RUN, THEN RUN THE APP
'''

app = Flask(__name__)

app.secret_key = "hello"
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///bets.sqlite3"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class bets(db.Model):
  _id = db.Column("id", db.Integer, primary_key=True)
  match = db.Column(db.String(100))
  scenario = db.Column(db.Integer)
  odds = db.Column(db.Integer)
  maxAmount = db.Column(db.Integer)
  maxAmountBuyable = db.Column(db.Integer)
  seller = db.Column(db.String(100))
  matched = db.Column(db.String(100))

  def __init__(self, match, scenario, odds, maxAmount, seller):#, buyer):
    self.match = match
    self.scenario = scenario
    self.odds = odds
    self.maxAmount = maxAmount
    self.maxAmountBuyable = int(maxAmount / odds)
    self.seller = seller
    self.matched = "nan"

class buyers(db.Model):
  _id = db.Column("id", db.Integer, primary_key=True)
  bet_id = db.Column(db.Integer)
  buyer = db.Column(db.String(100))
  perc = db.Column(db.Float)

  def __init__(self, bet_id, buyer, perc):
    self.bet_id = bet_id
    self.buyer = buyer
    self.perc = perc


@app.route("/")
def home():
  return render_template("index.html", values=matches)

@app.route("/seller/", methods=["POST", "GET"])
def seller():
  if request.method == "POST":
    form_data = request.form
    if form_data["match"] and form_data["seller"] and form_data["scenario"] and form_data["odds"] and form_data["maxAmount"]: # check if all cells are filled
      if float(form_data["maxAmount"]) > 0 and float(form_data["odds"]) > 0: # other data validations: only integers larger than 0 allowed
        try: # check if funds are sufficients, if not gives us a valueError
          # add bet to blockchain
          seller_account = users.loc[users["user"]==form_data["seller"]]["account"].tolist()[0]
          seller_key = users.loc[users["user"]==form_data["seller"]]["key"].tolist()[0]
          builder = w3.eth.contract(abi=abi, bytecode=bytecode) # instantiate contract constructor
          tx = builder.constructor(form_data["match"], int(form_data["scenario"]), int(float(form_data["odds"])), int(float(form_data["maxAmount"]))).buildTransaction({
            'from': seller_account,
            'value': int(float(form_data["maxAmount"])),
            'nonce': w3.eth.getTransactionCount(seller_account)
          })
          signed_tx = w3.eth.account.signTransaction(tx, seller_key) # sign transaction
          tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction) # deploy contract constructor        
          tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash) # wait until the transaction is mined
          bets_list.append(w3.eth.contract(address=tx_receipt.contractAddress, abi=abi)) # create actual contract and append it to list
          print("Bet created by {}!".format(form_data["seller"]))
          # add bet to sql
          new_bet = bets(form_data["match"], form_data["scenario"], int(float(form_data["odds"])), int(float(form_data["maxAmount"])), form_data["seller"]) 
          db.session.add(new_bet)
          db.session.commit()
        except ValueError:
          print("Insufficient funds.")
    return render_template("seller.html", values=[ids, users["user"].tolist()])
  else:
    return render_template("seller.html", values=[ids, users["user"].tolist()])

@app.route("/buyer/", methods=["POST", "GET"])
def buyer():
  if request.method == "POST":
    form_data = request.form
    if form_data["buyer"] and form_data["id"] and form_data["amount"]:
      # check if buyer != seller
      key = bets.query.filter_by(_id=form_data["id"]).first()
      bet_seller = getattr(key, "seller")
      bet_maxbuyable = getattr(key, "maxAmountBuyable")
      if bet_seller != form_data["buyer"] and bet_maxbuyable >= int(float(form_data["amount"])):
        try: # check if funds are sufficients, if not gives us a valueError
          # update blockchain
          buyer_account = users.loc[users["user"]==form_data["buyer"]]["account"].tolist()[0]
          buyer_key = users.loc[users["user"]==form_data["buyer"]]["key"].tolist()[0]
          bet_id = int(form_data["id"]) - 1 # just because bets_list starts from 0 and everything else starts from 1
          tx = bets_list[bet_id].functions.buyBet().buildTransaction({
            'from': buyer_account,
            'value': int(float(form_data["amount"])),
            'nonce': w3.eth.getTransactionCount(buyer_account)
          })
          signed_tx = w3.eth.account.signTransaction(tx, buyer_key) # sign transaction
          tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction)
          w3.eth.waitForTransactionReceipt(tx_hash) # wait until the transaction is mined
          # update sql
          setattr(key, "matched", "M")
          perc_bought = int(float(form_data["amount"])) / (getattr(key, "maxAmount") / getattr(key, "odds"))
          new_buyer = buyers(int(form_data["id"]), form_data["buyer"], perc_bought) 
          db.session.add(new_buyer)
          new_max = bet_maxbuyable - int(float(form_data["amount"]))
          setattr(key, "maxAmountBuyable", new_max)
          db.session.commit()
          print("Bet bought by {}!".format(form_data["buyer"]))
        except ValueError:
          print("Insufficient funds.")
    return render_template("buyer.html", values=[bets.query.all(), users["user"].tolist()])
  else:
    return render_template("buyer.html", values=[bets.query.all(), users["user"].tolist()])
  
@app.route("/settled/")
def settled():
  print("Wait until the blockchain is updated...")
  time.sleep(10)
  print("Done!")
  for i in range(len(bets_list)):
    bet_winners = []
    key = bets.query.filter_by(_id=(i+1)).first()
    seller_account = users.loc[users["user"]==getattr(key, "seller")]["account"].tolist()[0]
    seller_key = users.loc[users["user"]==getattr(key, "seller")]["key"].tolist()[0]
    if getattr(key, "matched") == "nan": # not matched bets: seller is always the winner.
      bet_winners.append(seller_account)
      print("Bet {} winners: {}".format(i+1, getattr(key, "seller")))
      print("Bet {} balance: {}".format(i+1, bets_list[i].functions.checkContractBalance().call()))
      tx = bets_list[i].functions.withdrawBetNotMatched().buildTransaction({
        'from': seller_account,
        'value': 0,
        'nonce': w3.eth.getTransactionCount(seller_account)
      })
      signed_tx = w3.eth.account.signTransaction(tx, seller_key) # sign fake buy transaction
      tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction)
      w3.eth.waitForTransactionReceipt(tx_hash) # wait until the transaction is mined
      time.sleep(5) # sleep for 5 sec just to give time to update the transactionCount
    else: # matched bets: the winner depends on the result of settleBet()
      tx = bets_list[i].functions.settleBet().buildTransaction({
        'from': seller_account,
        'value': 0,
        'nonce': w3.eth.getTransactionCount(seller_account)
      })
      signed_tx = w3.eth.account.signTransaction(tx, seller_key) # sign transaction
      tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction)
      w3.eth.waitForTransactionReceipt(tx_hash) # wait until the transaction is mined
      buyers_win = bets_list[i].functions.settleBet().call()
      if buyers_win == True:
        buyers_keys = buyers.query.filter_by(bet_id=(i+1)).all()
        for k in range(len(buyers_keys)):
          bet_winners.append(getattr(buyers_keys[k], "buyer"))
      else:
        bet_winners.append(getattr(key, "seller"))
      print("Bet {} winners: {}".format(i+1, bet_winners))
      print("Bet {} balance: {}".format(i+1, bets_list[i].functions.checkContractBalance().call()))
      for bet_winner in bet_winners:
        winner_account = users.loc[users["user"]==bet_winner]["account"].tolist()[0]
        winner_key = users.loc[users["user"]==bet_winner]["key"].tolist()[0]
        
        parsed = False
        while not parsed:
          try: # sometimes if the bc is very busy the nonce doesn't update and gives us a valueError. If it does, we just try again after 5 sec.
            tx = bets_list[i].functions.withdrawGains().buildTransaction({
              'from': winner_account,
              'value': 0,
              'nonce': w3.eth.getTransactionCount(winner_account)
            })
            signed_tx = w3.eth.account.signTransaction(tx, winner_key) # sign transaction
            tx_hash = w3.eth.sendRawTransaction(signed_tx.rawTransaction)
            w3.eth.waitForTransactionReceipt(tx_hash) # wait until the transaction is mined
            parsed = True
          except ValueError:
            print("Blockchain needs more time to update...")
            time.sleep(5)
     
    print("Bet settled!")
  bets_list.clear()
  db.drop_all()
  db.create_all()
  return render_template("settled.html")

@app.route("/contacts/")
def contacts():
  return render_template("contacts.html")


if __name__ == "__main__":
  db.drop_all()
  db.create_all()
  app.run()
