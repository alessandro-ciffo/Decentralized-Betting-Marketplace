import flask
from flask import request, jsonify
import json

app = flask.Flask(__name__)
app.config["DEBUG"] = True

with open('./api/match.json') as f:
    matches = json.load(f)

print(matches)

@app.route('/', methods=['GET'])
def home():
    return '''<h1>Decentralized Betting Marketplace</h1>
<p>The first place where you can buy and sell bets in a decentralized fashion.</p>'''


@app.route('/api/v1/matches/', methods=['GET'])
def api_name():
    # Query API by name using teams field
    if 'name' in request.args:
        name = str(request.args['name'])
    else:
        return "Error: No name field provided. Please specify a name."

    # Create an empty list for our results
    results = []

    # Loop through the data and match results that fit the requested name.
    if matches["CONTRACT"]["teams"] == name:
        results.append(matches)
    

    # Use the jsonify function from Flask to convert our list of
    # Python dictionaries to the JSON format.
    return jsonify(matches)


if __name__ == "__main__":
    app.run()