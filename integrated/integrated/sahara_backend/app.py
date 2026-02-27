"""
Sahara Backend – Integrated Server (Phases 1 + 2 + 3 merged)
Run:  python app.py
Flutter connects to http://localhost:5000
"""

import os
import re
import json
import numpy as np
import librosa
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

# ── Lazy imports (heavy) ────────────────────────────────────────────────
_embedder          = None
_llm               = None
_vosk_models       = {}
_chroma_collection = None


def get_embedder():
    global _embedder
    if _embedder is None:
        from sentence_transformers import SentenceTransformer
        _embedder = SentenceTransformer('all-MiniLM-L6-v2')
        print("✅ Embedder loaded.")
    return _embedder


def get_llm():
    global _llm
    if _llm is None:
        from llama_cpp import Llama
        model_path = os.environ.get(
            'LLM_MODEL_PATH',
            './models/phi-3-mini-4k-instruct-q4.gguf'
        )
        if not os.path.exists(model_path):
            raise FileNotFoundError(
                f"LLM model not found at '{model_path}'.\n"
                "Download from: https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf\n"
                "Set env var LLM_MODEL_PATH if placed elsewhere."
            )
        print(f"Loading LLM from {model_path} ...")
        _llm = Llama(
            model_path=model_path,
            n_ctx=2048,
            n_threads=int(os.environ.get('LLM_THREADS', '4')),
            n_gpu_layers=int(os.environ.get('LLM_GPU_LAYERS', '0')),
            verbose=False,
        )
        print("✅ LLM loaded.")
    return _llm


def get_vosk_models():
    global _vosk_models
    if not _vosk_models:
        vosk_paths = {
            'hi':    os.environ.get('VOSK_HI',   './vosk_models/vosk-model-small-hi-0.22'),
            'en-in': os.environ.get('VOSK_EN_IN', './vosk_models/vosk-model-small-en-in-0.4'),
        }
        try:
            from vosk import Model
            for lang, path in vosk_paths.items():
                if os.path.exists(path):
                    _vosk_models[lang] = Model(path)
                    print(f"✅ Vosk model loaded: {lang}")
                else:
                    print(f"⚠️  Vosk model not found for '{lang}' at {path}")
        except ImportError:
            print("⚠️  Vosk not installed. Voice features disabled.")
    return _vosk_models


def get_collection(collection_name: str = 'sahara_memories'):
    global _chroma_collection
    if _chroma_collection is None:
        try:
            import chromadb
            client = chromadb.PersistentClient(path="./chroma_db")
            try:
                _chroma_collection = client.get_collection(name=collection_name)
                print("✅ ChromaDB collection loaded.")
            except Exception:
                _chroma_collection = None  # not yet indexed
        except Exception as e:
            print(f"⚠️  ChromaDB error: {e}")
            _chroma_collection = None
    return _chroma_collection


# ══════════════════════════════════════════════════════════════════════════
# Phase 1 – RAG helpers
# ══════════════════════════════════════════════════════════════════════════

def parse_whatsapp_chat(file_path: str):
    """Parse _chat.txt and return list of {date, sender, message} dicts."""
    messages = []
    date_pattern     = r'\[(\d{1,2}/\d{1,2}/\d{4}), (\d{1,2}:\d{2}:\d{2} (?:AM|PM))\] (.*?): (.*)'
    fallback_pattern = r'(\d{1,2}/\d{1,2}/\d{2,4}), (\d{1,2}:\d{2}(?::\d{2})? (?:AM|PM)) - (.*?): (.*)'
    date_formats     = [
        '%d/%m/%Y %I:%M:%S %p',
        '%m/%d/%y %I:%M %p',
        '%d/%m/%y %H:%M',
        '%d/%m/%Y %I:%M %p',
        '%m/%d/%Y %I:%M:%S %p',
    ]

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        current_message = None
        for line in f:
            line = line.strip()
            if not line:
                continue
            match = re.match(date_pattern, line) or re.match(fallback_pattern, line)
            if match:
                groups = match.groups()
                if len(groups) == 4:
                    date_str, time_str, sender, message = groups
                    date_obj = None
                    for fmt in date_formats:
                        try:
                            date_obj = datetime.strptime(
                                f"{date_str} {time_str}", fmt)
                            break
                        except ValueError:
                            continue
                    if date_obj:
                        current_message = {
                            'date':    date_obj,
                            'sender':  sender.strip(),
                            'message': message.strip(),
                        }
                        messages.append(current_message)
            elif current_message:
                current_message['message'] += ' ' + line

    return messages


def build_vector_store(messages: list, collection_name: str = 'sahara_memories'):
    """Embed messages and persist to ChromaDB. Returns count."""
    import chromadb
    client = chromadb.PersistentClient(path="./chroma_db")
    try:
        client.delete_collection(collection_name)
    except Exception:
        pass
    collection = client.create_collection(name=collection_name)

    ids, documents, metadatas = [], [], []
    for i, msg in enumerate(messages):
        if msg['message'] and len(msg['message']) > 10:
            ids.append(str(i))
            documents.append(msg['message'])
            metadatas.append({
                'date':   msg['date'].isoformat(),
                'sender': msg['sender'],
            })

    if ids:
        embeddings = get_embedder().encode(documents).tolist()
        collection.add(
            ids=ids,
            embeddings=embeddings,
            metadatas=metadatas,
            documents=documents,
        )

    global _chroma_collection
    _chroma_collection = collection
    return len(ids)


def format_date_safe(iso_str: str) -> str:
    """Cross-platform date formatting (no %-d which breaks on Windows)."""
    try:
        d = datetime.fromisoformat(iso_str)
        return d.strftime('%d %b %Y').lstrip('0')   # '03 Feb 2024' → '3 Feb 2024'
    except Exception:
        return iso_str[:10]


def retrieve_memories(query: str, top_k: int = 5):
    """Return top_k relevant memories from ChromaDB."""
    collection = get_collection()
    if collection is None:
        return []

    try:
        query_emb = get_embedder().encode([query]).tolist()[0]
        results   = collection.query(
            query_embeddings=[query_emb],
            n_results=min(top_k, collection.count()),
            include=['documents', 'metadatas', 'distances'],
        )
        retrieved = []
        for i in range(len(results['ids'][0])):
            meta = results['metadatas'][0][i]
            retrieved.append({
                'text':   results['documents'][0][i],
                'date':   format_date_safe(meta.get('date', '')),
                'sender': meta.get('sender', ''),
                'score':  round(1 - results['distances'][0][i], 3),
            })
        return retrieved
    except Exception as e:
        print(f"⚠️  Retrieval error: {e}")
        return []


# ══════════════════════════════════════════════════════════════════════════
# Phase 2 – LLM generation
# ══════════════════════════════════════════════════════════════════════════

SYSTEM_PROMPT = """[Cultural Context: India, Maharashtra focus]
[Role: Gentle, empathetic AI companion named Sahara]
[Privacy: 100% on-device — never share data]

You are a kind, supportive friend helping someone feel less alone during grief or loneliness.
Use ONLY the provided retrieved memories from the user's own chat history.
NEVER invent memories. NEVER speak as the deceased loved one.

Response structure:
1. Acknowledge the user's feeling gently.
2. If relevant memories exist, share 1-2 warm moments neutrally.
3. Offer a small comforting suggestion.
4. End with a warm closing line.
5. ALWAYS end with: "I'm an AI companion, not a therapist. If you're feeling overwhelmed, please reach out to iCall (9152987821) or Vandrevala Foundation (9999666555)."

If no memories: offer gentle empathy + breathing suggestion + disclaimer.
Keep responses 80-150 words, warm, in simple Hindi/English mix if needed."""

CRISIS_RESPONSE = (
    "I'm really concerned for you right now. "
    "Please reach out for immediate help: "
    "Call iCall at 9152987821 or AASRA at 9820466726 right away. "
    "You are not alone. 🌿"
)

CRISIS_KEYWORDS = [
    "suicide", "end it", "kill myself", "want to die", "no point living",
    "मारना", "खत्म", "आत्महत्या", "मर जाना", "जीने का कोई मतलब नहीं",
]


def is_crisis_text(text: str) -> bool:
    t = text.lower()
    return any(kw.lower() in t for kw in CRISIS_KEYWORDS)


def generate_response(query: str, memories: list) -> str:
    llm = get_llm()

    if memories:
        ctx = "Relevant memories from your chats:\n"
        for i, m in enumerate(memories[:3], 1):
            doc = m['text'][:200] + '...' if len(m['text']) > 200 else m['text']
            ctx += f"[{i}] {m['date']} – {m['sender']}: {doc}\n"
    else:
        ctx = "No specific memories found for this moment."

    prompt = (
        f"{SYSTEM_PROMPT}\n\n"
        f"User said: \"{query}\"\n\n"
        f"{ctx}\n\n"
        f"Now respond gently and safely:"
    )

    resp = llm(
        prompt,
        max_tokens=200,
        temperature=0.7,
        top_p=0.9,
        stop=["</s>", "\n\n"],
        echo=False,
    )
    return resp['choices'][0]['text'].strip().replace("Sahara: ", "").strip()


# ══════════════════════════════════════════════════════════════════════════
# Phase 3 – Voice / distress detection
# ══════════════════════════════════════════════════════════════════════════

DISTRESS_PITCH_VAR = 150.0
DISTRESS_RMS       = 0.15
DISTRESS_ZCR       = 0.15


def detect_distress(audio_bytes: bytes, sample_rate: int = 16000) -> dict:
    try:
        y = np.frombuffer(audio_bytes, dtype=np.int16).astype(np.float32) / 32768.0
        if len(y) < 1000:
            return {'is_distressed': False, 'score': 0.0}

        rms          = librosa.feature.rms(y=y)[0]
        pitches, _   = librosa.piptrack(y=y, sr=sample_rate)
        pitch_values = pitches[pitches > 0]
        pitch_var    = float(np.var(pitch_values)) if len(pitch_values) > 0 else 0.0
        mean_rms     = float(np.mean(rms))
        zcr          = float(
            librosa.feature.zero_crossing_rate(y)[0].mean() * sample_rate / 2
        )

        score = 0.0
        if pitch_var > DISTRESS_PITCH_VAR: score += 0.4
        if mean_rms  > DISTRESS_RMS:       score += 0.4
        if zcr       > DISTRESS_ZCR:       score += 0.2

        return {'is_distressed': score >= 0.6, 'score': round(score, 3)}
    except Exception as e:
        print(f"⚠️  Distress detection error: {e}")
        return {'is_distressed': False, 'score': 0.0}


def transcribe_audio(audio_bytes: bytes, lang: str = 'hi') -> str:
    try:
        from vosk import KaldiRecognizer
        models = get_vosk_models()
        if lang not in models:
            lang = next(iter(models), None)
        if lang is None:
            return ''
        rec = KaldiRecognizer(models[lang], 16000)
        rec.AcceptWaveform(audio_bytes)
        result = json.loads(rec.FinalResult())
        return result.get('text', '').strip()
    except Exception as e:
        print(f"⚠️  Transcription error: {e}")
        return ''


# ══════════════════════════════════════════════════════════════════════════
# Flask App
# ══════════════════════════════════════════════════════════════════════════

app = Flask(__name__)
CORS(app)  # Allow Flutter on Chrome / emulator to reach local server


# ── /health ──────────────────────────────────────────────────────────────
@app.route('/health', methods=['GET'])
def health():
    # ✅ FIXED: don't call get_collection() on health — it may crash
    # Just report what's already loaded
    try:
        col        = get_collection()
        mem_count  = col.count() if col is not None else 0
        mem_ready  = col is not None
    except Exception:
        mem_count  = 0
        mem_ready  = False

    return jsonify({
        'status':           'ok',
        'llm_loaded':       _llm is not None,
        'embedder_loaded':  _embedder is not None,
        'memories_indexed': mem_ready,
        'memory_count':     mem_count,
        'vosk_langs':       list(_vosk_models.keys()),
    })


# ── /import  (WhatsApp chat upload) ──────────────────────────────────────
@app.route('/import', methods=['POST'])
def import_chat():
    """
    Accept _chat.txt upload, parse & embed it.
    Flutter sends multipart/form-data with field 'chat_file'.
    """
    try:
        if 'chat_file' not in request.files:
            return jsonify({'error': 'No chat_file in request. '
                            'Make sure field name is chat_file'}), 400

        file     = request.files['chat_file']
        tmp_path = f'./tmp_chat_{datetime.now().timestamp()}.txt'

        file.save(tmp_path)

        try:
            messages = parse_whatsapp_chat(tmp_path)
        finally:
            # Always clean up temp file
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

        if not messages:
            return jsonify({'error': 'No messages found in file. '
                            'Make sure it is a valid WhatsApp export.'}), 400

        count = build_vector_store(messages)
        return jsonify({
            'status':        'ok',
            'indexed':       count,
            'message_count': count,
        })

    except Exception as e:
        print(f"❌ /import error: {e}")
        return jsonify({'error': str(e)}), 500


# ── /generate  (text query → LLM response) ───────────────────────────────
@app.route('/generate', methods=['POST'])
def api_generate():
    try:
        data  = request.get_json(force=True)
        query = (data.get('query') or '').strip()

        if not query:
            return jsonify({'error': 'No query provided'}), 400

        # Crisis check first — no LLM needed
        if is_crisis_text(query):
            return jsonify({
                'response':        CRISIS_RESPONSE,
                'is_crisis':       True,
                'retrieved_count': 0,
                'memories_sample': [],
            })

        # Check if memories are indexed
        collection = get_collection()
        if collection is None:
            return jsonify({
                'response': (
                    'I haven\'t learned your memories yet. '
                    'Please import your WhatsApp chat first using the import screen.'
                ),
                'is_crisis':       False,
                'retrieved_count': 0,
                'memories_sample': [],
            })

        # Check if LLM is available
        try:
            memories      = retrieve_memories(query, top_k=5)
            response_text = generate_response(query, memories)
        except FileNotFoundError as e:
            return jsonify({
                'response': (
                    'The AI model hasn\'t been downloaded yet. '
                    'Please download Phi-3-mini GGUF and place it in the models/ folder.'
                ),
                'is_crisis':       False,
                'retrieved_count': 0,
                'memories_sample': [],
            })

        return jsonify({
            'response':        response_text,
            'retrieved_count': len(memories),
            'memories_sample': memories[:2],
            'is_crisis':       False,
        })

    except Exception as e:
        print(f"❌ /generate error: {e}")
        return jsonify({'error': str(e)}), 500


# ── /voice_query  (audio → transcribe → LLM) ─────────────────────────────
@app.route('/voice_query', methods=['POST'])
def voice_query():
    try:
        if 'audio' not in request.files:
            return jsonify({'error': 'No audio file provided'}), 400

        audio_file  = request.files['audio']
        lang        = request.form.get('lang', 'hi')
        audio_bytes = audio_file.read()

        text_query = transcribe_audio(audio_bytes, lang)
        if not text_query:
            return jsonify({'error': 'No speech detected. Please try again.'}), 400

        distress = detect_distress(audio_bytes)

        if is_crisis_text(text_query) or distress['is_distressed']:
            return jsonify({
                'response':       CRISIS_RESPONSE,
                'transcribed':    text_query,
                'is_crisis':      True,
                'is_distressed':  distress['is_distressed'],
                'distress_score': distress['score'],
                'retrieved_count': 0,
                'memories_sample': [],
            })

        memories      = retrieve_memories(text_query, top_k=5)
        response_text = generate_response(text_query, memories)

        return jsonify({
            'response':        response_text,
            'transcribed':     text_query,
            'is_crisis':       False,
            'is_distressed':   distress['is_distressed'],
            'distress_score':  distress['score'],
            'retrieved_count': len(memories),
            'memories_sample': memories[:2],
        })

    except Exception as e:
        print(f"❌ /voice_query error: {e}")
        return jsonify({'error': str(e)}), 500


# ══════════════════════════════════════════════════════════════════════════

if __name__ == '__main__':
    print("=" * 60)
    print("  Sahara Backend – Integrated Server")
    print("  http://0.0.0.0:5000")
    print("=" * 60)
    print("\nEndpoints:")
    print("  GET  /health       – status check")
    print("  POST /import       – upload _chat.txt (field: chat_file)")
    print("  POST /generate     – JSON {'query': '...'}")
    print("  POST /voice_query  – multipart audio (field: audio)")
    print("\nSetup:")
    print("  1. pip install -r requirements.txt")
    print("  2. Place model at ./models/phi-3-mini-4k-instruct-q4.gguf")
    print("  3. Download Vosk models to ./vosk_models/")
    print("=" * 60)
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)