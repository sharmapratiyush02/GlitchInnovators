"""
Sahara Phase 3 — Voice & Safety
=================================
1. Offline STT via Vosk (Hindi/Marathi/English)
2. Distress detection via pitch + energy analysis (librosa)
3. Crisis protocol — auto-triggers if distress is high

Install:
  pip install vosk librosa sounddevice numpy flask
  
Download Vosk model (Hindi, works for Marathi too):
  wget https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip
  unzip vosk-model-small-hi-0.22.zip -d ./vosk_model
"""

import io, json, wave, numpy as np, librosa, sounddevice as sd
from vosk import Model, KaldiRecognizer
from flask import Flask, request, jsonify

# ── Load Vosk STT model (offline, on-device) ──────────────────────────────────
print("🔄 Loading Vosk STT model...")
STT_MODEL   = Model("./vosk_model/vosk-model-small-hi-0.22")
SAMPLE_RATE = 16000
print("✅ Vosk ready!")

# ── 1. Speech-to-Text ─────────────────────────────────────────────────────────
def transcribe(audio_bytes: bytes) -> str:
    """Convert raw WAV audio bytes → text using Vosk (fully offline)."""
    rec = KaldiRecognizer(STT_MODEL, SAMPLE_RATE)
    rec.AcceptWaveform(audio_bytes)
    result = json.loads(rec.FinalResult())
    return result.get("text", "").strip()


# ── 2. Distress Detector ──────────────────────────────────────────────────────
def analyze_distress(audio_bytes: bytes) -> dict:
    """
    Analyze voice audio for emotional distress signals.
    Uses 3 acoustic features as proxy:
      - Pitch variance   → high = agitated / anxious
      - Speech rate      → fast = panic / distress  
      - Energy (RMS)     → loud/erratic = emotional dysregulation
    Returns: { score: 0-1, level: calm/mild/high, flags: [...] }
    """
    # Load audio from bytes
    audio, sr = librosa.load(io.BytesIO(audio_bytes), sr=SAMPLE_RATE, mono=True)

    flags = []
    score = 0.0

    # Pitch variance (F0)
    f0, _, _ = librosa.pyin(audio, fmin=80, fmax=400, sr=sr)
    f0_clean  = f0[~np.isnan(f0)]
    if len(f0_clean) > 10:
        pitch_var = float(np.std(f0_clean))
        if pitch_var > 60:
            flags.append("high_pitch_variance")
            score += 0.35

    # Energy / RMS
    rms      = librosa.feature.rms(y=audio)[0]
    rms_var  = float(np.std(rms))
    rms_mean = float(np.mean(rms))
    if rms_var > 0.02:
        flags.append("erratic_energy")
        score += 0.30
    if rms_mean > 0.08:
        flags.append("loud_speech")
        score += 0.15

    # Speech rate via zero-crossing rate (proxy)
    zcr      = librosa.feature.zero_crossing_rate(audio)[0]
    zcr_mean = float(np.mean(zcr))
    if zcr_mean > 0.15:
        flags.append("fast_speech_rate")
        score += 0.20

    score = round(min(score, 1.0), 2)
    level = "high" if score >= 0.6 else "mild" if score >= 0.3 else "calm"

    return {"score": score, "level": level, "flags": flags}


# ── 3. Crisis keywords (EN + HI + MR) ────────────────────────────────────────
CRISIS_WORDS = [
    "suicide", "kill myself", "end my life", "want to die",
    "jeena nahi", "marna chahta", "jiv dyaycha", "sampvaycha", "nako aata"
]

CRISIS_RESPONSE = {
    "response": "💙 Tum akele nahi ho. Please abhi inhe call karo:\n\n"
                "• iCall: 9152987821\n"
                "• Vandrevala: 1860-2662-345 (24/7)\n"
                "• SNEHI: 044-24640050\n\n"
                "Sahara tumhare saath hai. 🙏",
    "crisis": True
}

def is_crisis(text: str) -> bool:
    return any(kw in text.lower() for kw in CRISIS_WORDS)


# ── 4. Flask endpoint ─────────────────────────────────────────────────────────
app = Flask(__name__)

@app.route("/voice", methods=["POST"])
def voice():
    """
    Accepts: multipart WAV audio file
    Returns: { transcript, distress, crisis, forward_to_llm }
    
    React Native sends audio as:
      const form = new FormData();
      form.append('audio', { uri, type: 'audio/wav', name: 'voice.wav' });
      fetch('http://127.0.0.1:5007/voice', { method: 'POST', body: form });
    """
    if "audio" not in request.files:
        return jsonify({"error": "audio file required"}), 400

    audio_bytes = request.files["audio"].read()

    # Step 1 — Transcribe
    transcript = transcribe(audio_bytes)
    if not transcript:
        return jsonify({"error": "Could not understand audio"}), 422

    # Step 2 — Crisis keyword check (always first)
    if is_crisis(transcript):
        return jsonify({**CRISIS_RESPONSE, "transcript": transcript, "distress": None})

    # Step 3 — Distress analysis
    distress = analyze_distress(audio_bytes)

    # Step 4 — If high distress, override with calming response before LLM
    if distress["level"] == "high":
        return jsonify({
            "transcript":      transcript,
            "distress":        distress,
            "crisis":          False,
            "calming_prompt":  True,
            "response":        "🌬️ Main sun raha/rahi hoon... Pehle ek gehri saans lo. "
                               "Saath mein... andar... aur bahar. 💙\n\n"
                               "Ab batao, kya chal raha hai?",
            "forward_to_llm":  False,   # pause, calm first
        })

    # Step 5 — Safe to forward transcript to Phase 2 LLM
    return jsonify({
        "transcript":     transcript,
        "distress":       distress,
        "crisis":         False,
        "forward_to_llm": True,         # React Native calls /chat with this transcript
    })


if __name__ == "__main__":
    print("🌿 Sahara Phase 3 voice bridge → http://127.0.0.1:5007")
    app.run(port=5007)