# aasman_backend.py
# ─────────────────────────────────────────────────────────────
# Aasman — Sahara Gathering Backend
#
# Architecture: Flask + Firebase Realtime Database + Socket.IO
# All data is anonymous — no user accounts, no real names.
# Users are identified only by a secure random token stored
# on-device. Tokens are never linked to any personal data.
#
# pip install flask flask-socketio firebase-admin
#             flask-cors python-dotenv
# ─────────────────────────────────────────────────────────────

import os
import uuid
import time
import secrets
import hashlib
from datetime import datetime, timezone
from functools import wraps

import firebase_admin
from firebase_admin import credentials, db as rtdb
from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit, join_room, leave_room
from flask_cors import CORS
from dotenv import load_dotenv

load_dotenv()

# ─────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────

FIREBASE_CRED_PATH  = os.getenv("FIREBASE_CRED_PATH", "./serviceAccountKey.json")
FIREBASE_DB_URL     = os.getenv("FIREBASE_DB_URL", "https://sahara-aasman.firebaseio.com")
SECRET_KEY          = os.getenv("SECRET_KEY", secrets.token_hex(32))

# Ritual time: 20:00 IST daily (UTC+5:30 = 14:30 UTC)
RITUAL_HOUR_UTC   = 14
RITUAL_MINUTE_UTC = 30
RITUAL_DURATION_S = 300   # 5 minutes

# Whisper limits
MAX_WHISPER_LENGTH   = 120
WHISPERS_PER_DAY     = 1
WHISPER_MODERATION   = True     # simple keyword filter

# Diya limits
DIYAS_PER_DAY        = 1
DIYA_INTENT_MAX_LEN  = 60

# Rate limiting (per anonymous token)
RATE_LIMIT_WINDOW_S  = 60
RATE_LIMIT_MAX_CALLS = 30

# ─────────────────────────────────────────────────────────────
# INITIALISE FIREBASE
# ─────────────────────────────────────────────────────────────

def init_firebase():
    """Initialise Firebase Admin SDK. Falls back to emulator for dev."""
    if os.getenv("FIREBASE_EMULATOR"):
        print("Using Firebase emulator (dev mode)")
        os.environ["FIREBASE_DATABASE_EMULATOR_HOST"] = "localhost:9000"
        app = firebase_admin.initialize_app(options={"databaseURL": FIREBASE_DB_URL})
    else:
        cred = credentials.Certificate(FIREBASE_CRED_PATH)
        app  = firebase_admin.initialize_app(cred, {"databaseURL": FIREBASE_DB_URL})
    return app

try:
    firebase_app = init_firebase()
    print("Firebase connected.")
except Exception as e:
    print(f"Firebase init failed: {e}")
    print("Running without Firebase — all data will be in-memory only.")
    firebase_app = None

# ─────────────────────────────────────────────────────────────
# FLASK + SOCKETIO
# ─────────────────────────────────────────────────────────────

app    = Flask(__name__)
app.config["SECRET_KEY"] = SECRET_KEY
CORS(app, resources={r"/api/*": {"origins": "*"}})
sio    = SocketIO(app, cors_allowed_origins="*", async_mode="threading")

# ─────────────────────────────────────────────────────────────
# ANONYMOUS TOKEN SYSTEM
# ─────────────────────────────────────────────────────────────

def get_token() -> str:
    """Extract the anonymous token from the request header."""
    return request.headers.get("X-Aasman-Token", "")

def hash_token(token: str) -> str:
    """One-way hash of the token for storage keys. Never store raw tokens."""
    return hashlib.sha256(token.encode()).hexdigest()[:16]

def require_token(f):
    """Decorator: reject requests without a valid anonymous token."""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = get_token()
        if not token or len(token) < 32:
            return jsonify({"error": "Missing or invalid token"}), 401
        return f(*args, **kwargs)
    return decorated

# ─────────────────────────────────────────────────────────────
# RATE LIMITING (simple in-memory, upgrade to Redis in prod)
# ─────────────────────────────────────────────────────────────

_rate_store: dict[str, list[float]] = {}

def is_rate_limited(token: str) -> bool:
    h   = hash_token(token)
    now = time.time()
    calls = _rate_store.get(h, [])
    calls = [t for t in calls if now - t < RATE_LIMIT_WINDOW_S]
    calls.append(now)
    _rate_store[h] = calls
    return len(calls) > RATE_LIMIT_MAX_CALLS

# ─────────────────────────────────────────────────────────────
# MODERATION (simple keyword block list — expand for production)
# ─────────────────────────────────────────────────────────────

BLOCKED_KEYWORDS = [
    "kill", "suicide", "end my life", "harm", "hurt myself",
    "मारना", "आत्महत्या",  # Hindi
    "abuse", "hate", "harass",
]

CRISIS_KEYWORDS = [
    "suicide", "end it", "kill myself", "आत्महत्या", "मर जाना",
]

def moderate_text(text: str) -> dict:
    """Returns {allowed: bool, is_crisis: bool, reason: str}"""
    lower = text.lower()
    if any(kw in lower for kw in CRISIS_KEYWORDS):
        return {"allowed": False, "is_crisis": True, "reason": "crisis"}
    if WHISPER_MODERATION and any(kw in lower for kw in BLOCKED_KEYWORDS):
        return {"allowed": False, "is_crisis": False, "reason": "content_policy"}
    return {"allowed": True, "is_crisis": False, "reason": "ok"}

CRISIS_RESPONSE = {
    "message": (
        "I noticed your words carry a lot of pain. "
        "Please reach out for immediate support: "
        "iCall: 9152987821 | AASRA: 9820466726. "
        "You are not alone. 💛"
    ),
    "resources": [
        {"name": "iCall", "number": "9152987821", "hours": "Mon-Sat 8am-9pm"},
        {"name": "AASRA", "number": "9820466726", "hours": "24/7"},
        {"name": "Vandrevala Foundation", "number": "9999666555", "hours": "24/7"},
    ]
}

# ─────────────────────────────────────────────────────────────
# FIREBASE HELPERS
# ─────────────────────────────────────────────────────────────

def fb_ref(path: str):
    """Get a Firebase Realtime DB reference, or None if unavailable."""
    if not firebase_app:
        return None
    return rtdb.reference(path)

def get_today_key() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")

def get_ritual_window() -> dict:
    """Returns whether the ritual is currently active and seconds until next."""
    now       = datetime.now(timezone.utc)
    ritual_dt = now.replace(hour=RITUAL_HOUR_UTC, minute=RITUAL_MINUTE_UTC, second=0, microsecond=0)
    if now > ritual_dt:
        ritual_dt = ritual_dt.replace(day=ritual_dt.day + 1)
    seconds_until = int((ritual_dt - now).total_seconds())
    is_active = seconds_until < RITUAL_DURATION_S and seconds_until >= 0
    return {
        "is_active": is_active,
        "seconds_until_next": seconds_until,
        "ritual_time_utc": f"{RITUAL_HOUR_UTC:02d}:{RITUAL_MINUTE_UTC:02d} UTC",
        "ritual_time_ist": "20:00 IST",
    }

# ─────────────────────────────────────────────────────────────
# API: TOKEN
# ─────────────────────────────────────────────────────────────

@app.route("/api/token", methods=["POST"])
def issue_token():
    """
    Issue a new anonymous token for a new device.
    The token is generated on-device in Flutter and registered here
    so we can track per-user limits without any personal data.
    """
    token = secrets.token_urlsafe(32)
    hashed = hash_token(token)

    ref = fb_ref(f"tokens/{hashed}")
    if ref:
        ref.set({
            "created_at": datetime.now(timezone.utc).isoformat(),
            "diya_today": False,
            "whisper_today": False,
        })

    return jsonify({"token": token})

# ─────────────────────────────────────────────────────────────
# API: SKY STATS
# ─────────────────────────────────────────────────────────────

@app.route("/api/sky", methods=["GET"])
@require_token
def get_sky():
    """Returns live sky stats: star count, whisper count, ritual window."""
    today = get_today_key()
    ref   = fb_ref(f"stats/{today}")

    if ref:
        stats = ref.get() or {}
        star_count    = stats.get("diyas_lit", 0)
        whisper_count = stats.get("whispers_sent", 0)
    else:
        star_count    = 247
        whisper_count = 84

    ritual = get_ritual_window()

    return jsonify({
        "stars_tonight": star_count,
        "whispers_tonight": whisper_count,
        "ritual": ritual,
        "date": today,
    })

# ─────────────────────────────────────────────────────────────
# API: DIYAS
# ─────────────────────────────────────────────────────────────

@app.route("/api/diyas", methods=["GET"])
@require_token
def get_diyas():
    """Returns today's diya wall — list of colours + intentions (no tokens)."""
    today = get_today_key()
    ref   = fb_ref(f"diyas/{today}")

    if ref:
        data   = ref.get() or {}
        diyas  = [v for v in data.values()]
    else:
        # Fallback demo data
        diyas = [
            {"color": "#d4874e", "intent": "for Aai", "lit_at": "20:31"},
            {"color": "#e8b86d", "intent": "for Baba", "lit_at": "20:29"},
            {"color": "#5a9e8a", "intent": "with hope", "lit_at": "20:28"},
        ]

    return jsonify({"diyas": diyas, "count": len(diyas)})


@app.route("/api/diyas", methods=["POST"])
@require_token
def light_diya():
    """Light a diya. One per token per day."""
    token  = get_token()
    hashed = hash_token(token)

    if is_rate_limited(token):
        return jsonify({"error": "Rate limit exceeded"}), 429

    today = get_today_key()

    # Check if already lit today
    token_ref = fb_ref(f"tokens/{hashed}")
    if token_ref:
        token_data = token_ref.get() or {}
        if token_data.get("diya_today") == today:
            return jsonify({"error": "Already lit today", "code": "already_lit"}), 409

    body   = request.json or {}
    color  = body.get("color", "#d4874e")
    intent = (body.get("intent") or "")[:DIYA_INTENT_MAX_LEN].strip()

    # Moderate the intent text
    if intent:
        mod = moderate_text(intent)
        if mod["is_crisis"]:
            return jsonify({"error": "crisis", "response": CRISIS_RESPONSE}), 200
        if not mod["allowed"]:
            return jsonify({"error": "Content not allowed"}), 422

    diya_data = {
        "color":   color,
        "intent":  intent,
        "lit_at":  datetime.now(timezone.utc).strftime("%H:%M"),
        "date":    today,
    }

    diya_ref = fb_ref(f"diyas/{today}")
    if diya_ref:
        diya_ref.push(diya_data)
        # Update daily counter
        stats_ref = fb_ref(f"stats/{today}/diyas_lit")
        if stats_ref:
            try:
                stats_ref.transaction(lambda v: (v or 0) + 1)
            except Exception:
                pass
        # Mark token as used today
        if token_ref:
            token_ref.update({"diya_today": today})

    # Broadcast to all connected clients
    sio.emit("diya_lit", diya_data, room="sky")

    return jsonify({"success": True, "diya": diya_data}), 201

# ─────────────────────────────────────────────────────────────
# API: WHISPERS
# ─────────────────────────────────────────────────────────────

@app.route("/api/whispers", methods=["GET"])
@require_token
def get_whispers():
    """Returns today's whispers — paginated, most recent first."""
    today  = get_today_key()
    limit  = min(int(request.args.get("limit", 20)), 50)
    ref    = fb_ref(f"whispers/{today}")

    if ref:
        data     = ref.order_by_child("sent_at").limit_to_last(limit).get() or {}
        whispers = sorted(data.values(), key=lambda x: x.get("sent_at",""), reverse=True)
    else:
        whispers = [
            {"text": "She used to hum while making tea. I can still hear it.", "echoes": 34, "color": "#d4874e"},
            {"text": "Some days I am okay. Today I am not. And that is okay.", "echoes": 52, "color": "#5a9e8a"},
        ]

    return jsonify({"whispers": whispers, "count": len(whispers)})


@app.route("/api/whispers", methods=["POST"])
@require_token
def send_whisper():
    """Release a whisper into the sky. One per token per day."""
    token  = get_token()
    hashed = hash_token(token)

    if is_rate_limited(token):
        return jsonify({"error": "Rate limit exceeded"}), 429

    today  = get_today_key()

    # Check daily limit
    token_ref = fb_ref(f"tokens/{hashed}")
    if token_ref:
        token_data = token_ref.get() or {}
        if token_data.get("whisper_today") == today:
            return jsonify({"error": "One whisper per day", "code": "limit_reached"}), 409

    body = request.json or {}
    text = (body.get("text") or "").strip()

    if not text:
        return jsonify({"error": "Text required"}), 400
    if len(text) > MAX_WHISPER_LENGTH:
        return jsonify({"error": f"Max {MAX_WHISPER_LENGTH} characters"}), 400

    # Moderation
    mod = moderate_text(text)
    if mod["is_crisis"]:
        return jsonify({"error": "crisis", "response": CRISIS_RESPONSE}), 200
    if not mod["allowed"]:
        return jsonify({"error": "Content not allowed by community guidelines"}), 422

    color = body.get("color", "#d4874e")
    whisper_data = {
        "text":    text,
        "color":   color,
        "echoes":  0,
        "sent_at": datetime.now(timezone.utc).isoformat(),
        "date":    today,
    }

    whisper_ref = fb_ref(f"whispers/{today}")
    if whisper_ref:
        new_ref = whisper_ref.push(whisper_data)
        whisper_data["id"] = new_ref.key
        # Update counter
        stats_ref = fb_ref(f"stats/{today}/whispers_sent")
        if stats_ref:
            try:
                stats_ref.transaction(lambda v: (v or 0) + 1)
            except Exception:
                pass
        # Mark token
        if token_ref:
            token_ref.update({"whisper_today": today})

    # Broadcast
    sio.emit("new_whisper", whisper_data, room="sky")

    return jsonify({"success": True, "whisper": whisper_data}), 201


@app.route("/api/whispers/<whisper_id>/echo", methods=["POST"])
@require_token
def echo_whisper(whisper_id):
    """Add or remove your echo from a whisper."""
    token  = get_token()
    hashed = hash_token(token)
    today  = get_today_key()

    echo_key = f"echoes/{today}/{whisper_id}/{hashed}"
    echo_ref = fb_ref(echo_key)

    if echo_ref:
        existing = echo_ref.get()
        if existing:
            # Un-echo
            echo_ref.delete()
            w_ref = fb_ref(f"whispers/{today}/{whisper_id}/echoes")
            if w_ref:
                w_ref.transaction(lambda v: max((v or 1) - 1, 0))
            action = "removed"
        else:
            # Echo
            echo_ref.set(True)
            w_ref = fb_ref(f"whispers/{today}/{whisper_id}/echoes")
            if w_ref:
                w_ref.transaction(lambda v: (v or 0) + 1)
            action = "added"
    else:
        action = "added"

    return jsonify({"success": True, "action": action})

# ─────────────────────────────────────────────────────────────
# API: RITUAL
# ─────────────────────────────────────────────────────────────

@app.route("/api/ritual", methods=["GET"])
@require_token
def get_ritual():
    """Returns ritual status, tonight's prompt, and live participant count."""
    ritual = get_ritual_window()
    today  = get_today_key()

    # Tonight's reflection prompt (rotate weekly)
    prompts = [
        "What is one small thing that made you smile today — even for a moment?",
        "Think of a sound you associate with your loved one. Sit with it for a breath.",
        "What would you want them to know about who you are becoming?",
        "Name one thing they gave you — not an object, but a quality or a memory.",
        "What would they say to you right now, in this moment?",
        "Think of a meal, a place, or a song that carries them. Be there for a moment.",
        "What part of them lives in you? Breathe into that.",
    ]
    day_of_week = datetime.now(timezone.utc).weekday()
    prompt      = prompts[day_of_week]

    # Live participant count
    participants_ref = fb_ref(f"ritual_sessions/{today}/participants")
    participant_count = 0
    if participants_ref:
        data = participants_ref.get() or {}
        participant_count = len(data)

    return jsonify({
        "ritual": ritual,
        "prompt": prompt,
        "participants_now": participant_count,
        "description": "Every evening at 8 PM IST, everyone in Aasman breathes together for 5 minutes.",
    })


@app.route("/api/ritual/join", methods=["POST"])
@require_token
def join_ritual():
    """Register presence in tonight's ritual session."""
    token  = get_token()
    hashed = hash_token(token)
    today  = get_today_key()

    ref = fb_ref(f"ritual_sessions/{today}/participants/{hashed}")
    if ref:
        ref.set({
            "joined_at": datetime.now(timezone.utc).isoformat(),
            "active": True,
        })

    # Broadcast updated count
    participants_ref = fb_ref(f"ritual_sessions/{today}/participants")
    count = 0
    if participants_ref:
        data  = participants_ref.get() or {}
        count = len(data)

    sio.emit("ritual_participant_count", {"count": count}, room="ritual")

    return jsonify({"success": True, "participants": count})


@app.route("/api/ritual/leave", methods=["POST"])
@require_token
def leave_ritual():
    """Remove presence from tonight's ritual."""
    token  = get_token()
    hashed = hash_token(token)
    today  = get_today_key()

    ref = fb_ref(f"ritual_sessions/{today}/participants/{hashed}")
    if ref:
        ref.delete()

    return jsonify({"success": True})

# ─────────────────────────────────────────────────────────────
# SOCKET.IO — Real-time events
# ─────────────────────────────────────────────────────────────

@sio.on("connect")
def on_connect():
    """Client connected — join the shared sky room."""
    join_room("sky")
    emit("sky_welcome", {"message": "You are in the sky. You are not alone."})

@sio.on("join_ritual")
def on_join_ritual(data):
    join_room("ritual")
    emit("ritual_joined", {"message": "Breathing together."})

@sio.on("leave_ritual")
def on_leave_ritual(data):
    leave_room("ritual")

@sio.on("disconnect")
def on_disconnect():
    leave_room("sky")
    leave_room("ritual")

# ─────────────────────────────────────────────────────────────
# PRIVACY: Data expiry (run as nightly cron)
# ─────────────────────────────────────────────────────────────

def purge_old_data(days_to_keep: int = 7):
    """
    Deletes all Aasman data older than `days_to_keep` days.
    Whispers, diyas, ritual sessions — all ephemeral by design.
    Call this as a scheduled Cloud Function or nightly cron job.
    """
    from datetime import timedelta
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days_to_keep)).strftime("%Y-%m-%d")
    for path in ["diyas", "whispers", "ritual_sessions", "stats", "echoes"]:
        ref = fb_ref(path)
        if ref:
            data = ref.get() or {}
            for date_key in data:
                if date_key < cutoff:
                    fb_ref(f"{path}/{date_key}").delete()
                    print(f"Purged {path}/{date_key}")

@app.route("/api/admin/purge", methods=["POST"])
def admin_purge():
    """Admin endpoint to trigger data purge. Protect with a secret in production."""
    admin_key = request.headers.get("X-Admin-Key")
    if admin_key != os.getenv("ADMIN_KEY", ""):
        return jsonify({"error": "Unauthorized"}), 403
    purge_old_data()
    return jsonify({"success": True})

# ─────────────────────────────────────────────────────────────
# HEALTH
# ─────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    ritual = get_ritual_window()
    return jsonify({
        "status": "ok",
        "firebase": firebase_app is not None,
        "ritual_active": ritual["is_active"],
        "seconds_until_ritual": ritual["seconds_until_next"],
    })

# ─────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("Starting Aasman backend on http://localhost:5001")
    print("Ritual scheduled at 20:00 IST daily")
    print("Data auto-purges after 7 days — whispers are ephemeral by design")
    sio.run(app, host="0.0.0.0", port=5001, debug=False)