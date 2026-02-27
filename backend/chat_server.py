from flask import Flask, request, jsonify
from rag import generate_response

app = Flask(__name__)

@app.route("/chat", methods=["POST"])
def chat():
    data = request.json
    message = data.get("message", "")

    if not message:
        return jsonify({"error": "message required"}), 400

    response = generate_response(message)

    return jsonify({"response": response})


if __name__ == "__main__":
    print("🌿 Sahara Phase 2 Chat API → http://127.0.0.1:5006")
    app.run(port=5006)