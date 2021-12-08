import flask
from flask import request, jsonify
import json

app = flask.Flask(__name__)
app.config["DEBUG"] = True

with open('./example_matches.json') as f:
    matches = json.load(f)

@app.route('/', methods=['GET'])
def home():
    return matches #'''<h1>Distant Reading Archive</h1>
#<p>A prototype API for distant reading of science fiction novels.</p>'''

@app.route('/api/v1/matches/', methods=['GET'])
def api_id():
    # Check if an ID was provided as part of the URL.
    # If ID is provided, assign it to a variable.
    # If no ID is provided, display an error in the browser.
    if 'id' in request.args:
        id = int(request.args['id'])
    else:
        return "Error: No id field provided. Please specify an id."

    # Create an empty list for our results
    results = []

    # Loop through the data and match results that fit the requested ID.
    # IDs are unique, but other fields might return many results
    for match in matches:
        if match['id'] == id:
            results.append(match)
            break

    # Use the jsonify function from Flask to convert our list of
    # Python dictionaries to the JSON format.
    return jsonify(results[0])


# # A route to return all of the available entries in our catalog.
# @app.route('/api/v1/matches/Juventus-Milan', methods=['GET'])
# def api_all():
#     with open('./api/example_match_1.json') as f:
#         data = json.load(f)
#     return data

if __name__ == "__main__":
    app.run()