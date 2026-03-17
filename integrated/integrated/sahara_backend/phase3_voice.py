import os
import json
import wave
import io
import numpy as np
import librosa
from flask import Flask, request, jsonify
from vosk import Model, KaldiRecognizer
import wave

VOSK_MODELS = {
    'hi': './vosk_models/vosk-model-small-hi-0.22',
    'en-in': './vosk_models/vosk-model-small-en-in-0.4',
}

DEFAULT_LANG = 'hi'

CRISIS_KEYWORDS = [
    "suicide", "end it", "kill myself", "die", "no point living",
    "मारना", "खत्म", "आत्महत्या", "मर जाना", "जीने का कोई मतलब नहीं"
]

DISTRESS_PITCH_VAR_THRESHOLD = 150.0
DISTRESS_RMS_THRESHOLD = 0.15
DISTRESS_FAST_SPEECH_THRESHOLD = 180

app = Flask(__name__)

vosk_models = {}
for lang, path in VOSK_MODELS.items():
    if os.path.exists(path):
        vosk_models[lang] = Model(path)
        print(f"Loaded Vosk model for {lang}")
    else:
        print(f"Warning: Vosk model not found for {lang} at {path}")

if not vosk_models:
    raise RuntimeError("No Vosk models loaded! Download and place in ./vosk_models/")

def detect_distress(audio_data: bytes, sample_rate: int = 16000) -> dict:
    y = np.frombuffer(audio_data, dtype=np.int16).astype(np.float32) / 32768.0
    if len(y) < 1000:
        return {'is_distressed': False, 'score': 0.0, 'details': {'error': 'audio too short'}}

    rms = librosa.feature.rms(y=y)[0]
    pitches, magnitudes = librosa.piptrack(y=y, sr=sample_rate)
    pitch_values = pitches[pitches > 0]
    pitch_var = np.var(pitch_values) if len(pitch_values) > 0 else 0.0

    mean_rms = np.mean(rms)
    details = {
        'mean_rms': float(mean_rms),
        'pitch_variance': float(pitch_var),
        'zcr': float(librosa.feature.zero_crossing_rate(y)[0].mean() * sample_rate / 2)
    }

    score = 0.0
    if pitch_var > DISTRESS_PITCH_VAR_THRESHOLD:
        score += 0.4
    if mean_rms > DISTRESS_RMS_THRESHOLD:
        score += 0.4
    if details['zcr'] > 0.15:
        score += 0.2

    is_distressed = score >= 0.6

    return {
        'is_distressed': is_distressed,
        'score': score,
        'details': details
    }

def transcribe_audio(audio_data: bytes, lang: str = DEFAULT_LANG) -> str:
    if lang not in vosk_models:
        lang = DEFAULT_LANG

    rec = KaldiRecognizer(vosk_models[lang], 16000)
    rec.AcceptWaveform(audio_data)
    result = json.loads(rec.FinalResult())
    return result.get('text', '').strip()

@app.route('/voice_query', methods=['POST'])
def voice_query():
    try:
        if 'audio' not in request.files:
            return jsonify({"error": "No audio file"}), 400

        audio_file = request.files['audio']
        lang = request.form.get('lang', DEFAULT_LANG)
        audio_bytes = audio_file.read()

        text_query = transcribe_audio(audio_bytes, lang)
        if not text_query:
            return jsonify({"error": "No speech detected"}), 400

        print(f"Transcribed: '{text_query}'")

        distress_info = detect_distress(audio_bytes)
        is_crisis = any(kw.lower() in text_query.lower() for kw in CRISIS_KEYWORDS)

        if is_crisis or distress_info['is_distressed']:
            emergency_msg = (
                "I'm really concerned for you right now. "
                "Please reach out for immediate help: "
                "Call iCall at 9152987821 or AASRA at 9820466726 right away. "
                "You're not alone."
            )
            return jsonify({
                "response": emergency_msg,
                "is_crisis": True,
                "distress_score": distress_info['score'],
                "transcribed": text_query
            })

        from phase1_rag import retrieve_memories
        from phase2_llm import generate_response

        memories = retrieve_memories(text_query, top_k=5)
        response_text = generate_response(text_query, memories)

        return jsonify({
            "response": response_text,
            "transcribed": text_query,
            "retrieved_count": len(memories),
            "distress_score": distress_info['score'],
            "is_distressed": distress_info['is_distressed']
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "ok",
        "vosk_langs": list(vosk_models.keys()),
        "llm_loaded": 'LLM' in globals()
    })

if __name__ == '__main__':
    print("Starting Sahara Phase 3 backend with Voice + Safety on http://localhost:5000")
    print("Flutter: Record voice → send WAV to /voice_query multipart form 'audio'")
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
