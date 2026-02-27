"""
Sahara Backend – Integrated Server
Run: python app.py
Flutter connects to http://localhost:5000
"""

import os
import re
import json
import pickle
import numpy as np
import librosa
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

VECTOR_STORE_PATH = './sahara_vectors.pkl'

_embedder = None
_llm = None
_vosk_models = {}
_vector_store = None

# =====================================================
# MODEL LOADERS
# =====================================================

def get_embedder():
    global _embedder
    if _embedder is None:
        from sentence_transformers import SentenceTransformer
        _embedder = SentenceTransformer('all-MiniLM-L6-v2')
        print("✅ Embedder loaded")
    return _embedder


def get_llm():
    global _llm
    if _llm is None:
        from llama_cpp import Llama
        model_path = './models/phi-3-mini-4k-instruct-q4.gguf'
        if not os.path.exists(model_path):
            raise FileNotFoundError("LLM model not found.")
        print("Loading LLM...")
        _llm = Llama(model_path=model_path, n_ctx=2048, n_threads=4, n_gpu_layers=0, verbose=False)
        print("✅ LLM loaded")
    return _llm


# =====================================================
# VECTOR STORE
# =====================================================

def load_vector_store():
    global _vector_store
    if _vector_store is not None:
        return _vector_store

    if os.path.exists(VECTOR_STORE_PATH):
        with open(VECTOR_STORE_PATH, 'rb') as f:
            _vector_store = pickle.load(f)
            print(f"✅ Loaded {_vector_store.get('documents') and len(_vector_store['documents'])} memories")

    return _vector_store


def save_vector_store(store):
    global _vector_store
    _vector_store = store
    with open(VECTOR_STORE_PATH, 'wb') as f:
        pickle.dump(store, f)


def cosine_similarity(a, b):
    a = a / (np.linalg.norm(a) + 1e-10)
    b = b / (np.linalg.norm(b, axis=1, keepdims=True) + 1e-10)
    return b @ a


def retrieve_memories(query, top_k=5):
    store = load_vector_store()
    if not store:
        return []

    query_emb = get_embedder().encode([query])[0]
    scores = cosine_similarity(query_emb, store['embeddings'])
    top_idx = np.argsort(scores)[::-1][:min(top_k, len(scores))]

    return [{
        'text': store['documents'][i],
        'date': store['metadatas'][i]['date'],
        'sender': store['metadatas'][i]['sender'],
        'score': float(scores[i])
    } for i in top_idx]


# =====================================================
# WHATSAPP PARSER
# =====================================================

def parse_whatsapp_chat(file_path):
    messages = []
    pattern = r'\[(\d+/\d+/\d+),\s*(.*?)\]\s*(.*?):\s*(.*)'

    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            match = re.match(pattern, line.strip())
            if match:
                date_str, time_str, sender, message = match.groups()
                try:
                    date_obj = datetime.strptime(f"{date_str} {time_str}", "%d/%m/%Y %H:%M:%S")
                except:
                    continue
                messages.append({
                    'date': date_obj.isoformat(),
                    'sender': sender,
                    'message': message
                })
    return messages


def build_vector_store(messages):
    docs = []
    metas = []

    for m in messages:
        if len(m['message']) > 10:
            docs.append(m['message'])
            metas.append({'date': m['date'], 'sender': m['sender']})

    if not docs:
        return 0

    embeddings = get_embedder().encode(docs)
    save_vector_store({
        'documents': docs,
        'metadatas': metas,
        'embeddings': embeddings
    })

    return len(docs)


# =====================================================
# LLM RESPONSE
# =====================================================

SYSTEM_PROMPT = """
You are Sahara, a gentle empathetic AI companion.
Use ONLY provided memories.
Never invent memories.
Always end with:
"I'm an AI companion, not a therapist. If overwhelmed, please call iCall (9152987821)."
"""

CRISIS_KEYWORDS = ["suicide","kill myself","want to die","no point living"]
CRISIS_RESPONSE = "I'm really concerned for you. Please call iCall (9152987821) immediately. You are not alone."


def is_crisis_text(text):
    t = text.lower()
    return any(k in t for k in CRISIS_KEYWORDS)


def generate_response(query, memories):
    llm = get_llm()

    context = ""
    if memories:
        context = "\n".join(
            f"{m['date']} - {m['sender']}: {m['text'][:200]}"
            for m in memories[:3]
        )

    prompt = f"{SYSTEM_PROMPT}\n\nUser: {query}\n\nMemories:\n{context}\n\nRespond gently:"

    resp = llm(prompt, max_tokens=200, temperature=0.7, top_p=0.9, stop=["</s>"])
    return resp['choices'][0]['text'].strip()


# =====================================================
# FLASK APP
# =====================================================

app = Flask(__name__)
CORS(app)


@app.route('/health')
def health():
    store = load_vector_store()
    count = len(store['documents']) if store else 0

    return jsonify({
        'status': 'ok',
        'llm_loaded': _llm is not None,
        'embedder_loaded': _embedder is not None,
        'memories_indexed': count > 0,
        'memory_count': count
    })


@app.route('/import', methods=['POST'])
def import_chat():
    try:
        if 'chat_file' not in request.files:
            return jsonify({'error': 'chat_file missing'}), 400

        file = request.files['chat_file']
        tmp_path = './temp_chat.txt'
        file.save(tmp_path)

        messages = parse_whatsapp_chat(tmp_path)
        os.remove(tmp_path)

        if not messages:
            return jsonify({'error': 'No messages found'}), 400

        count = build_vector_store(messages)

        return jsonify({'status': 'ok', 'indexed': count})

    except Exception as e:
        print("Import error:", e)
        return jsonify({'error': str(e)}), 500


@app.route('/generate', methods=['POST'])
def api_generate():
    try:
        data = request.get_json(force=True)
        query = (data.get('query') or '').strip()

        if not query:
            return jsonify({'error': 'No query provided'}), 400

        if is_crisis_text(query):
            return jsonify({'response': CRISIS_RESPONSE})

        store = load_vector_store()
        if not store:
            return jsonify({'response': "Please import your WhatsApp chat first."})

        memories = retrieve_memories(query)

        try:
            response_text = generate_response(query, memories)
            if not response_text:
                raise ValueError("Empty response")

        except Exception:
            # Fallback response
            if memories:
                mem = memories[0]
                response_text = (
                    f"I found a memory from {mem['date']} — "
                    f"{mem['sender']} said: \"{mem['text']}\"\n\n"
                    "I'm here with you. 🌿\n\n"
                    "I'm an AI companion, not a therapist. "
                    "If overwhelmed, please call iCall (9152987821)."
                )
            else:
                response_text = (
                    "I couldn't find a specific memory, "
                    "but I'm here with you. 🌿\n\n"
                    "I'm an AI companion, not a therapist. "
                    "If overwhelmed, please call iCall (9152987821)."
                )

        return jsonify({'response': response_text})

    except Exception as e:
        print("Generate error:", e)
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    print("Sahara Backend running at http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)