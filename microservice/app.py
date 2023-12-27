from flask import Flask, request, jsonify
import os

app = Flask(__name__)

EXPECTED_API_KEY = os.environ.get('EXPECTED_API_KEY')

@app.route('/v<int:major_version>/DevOps', methods=['POST'])
@app.route('/DevOps', methods=['POST'])
def devops_endpoint(major_version=None):
    api_key = request.headers.get('X-Parse-REST-API-Key')
    if api_key != EXPECTED_API_KEY:
        return jsonify({"message": "Error: Provide correct X-Parse-REST-API-Key HTTP Header, and message/to/from/timeToLifeSec in your request payload"}), 401

    data = request.json
    if not data or 'to' not in data or 'from' not in data:
        return jsonify({"major_version": major_version, "message": "Error: Missing required fields in the request payload"}), 400

    sender_name = data['from']
    receiver_name = data['to']

    response_message = f"Hello {sender_name} your message will be sent to {receiver_name}."
    return jsonify({"major_version": major_version, "message": response_message})

@app.route('/', methods=['GET'])
def health_check():
    return 'This app works with POST /DevOps locally or with /v1/DevOps, /v2/DevOps, etc when remotely accessed', 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)

