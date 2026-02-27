# 🌿 Sahara – Privacy-First Mental Health Support Companion  
### Problem Code: 26001 – Mental Health Support Apps

---

## 🧩 Problem Statement

Chatbots and digital therapy tools to bridge the mental health support gap.

India is witnessing a rapid rise in stress, anxiety, depression, and other mental health concerns. However, access to timely and affordable mental health support remains limited due to stigma, shortage of trained professionals, and unequal distribution of services.

This project aims to design an innovative, scalable, and accessible digital support system that enables:

- Early emotional distress detection  
- Anonymous and privacy-sensitive interaction  
- Multilingual accessibility  
- AI-assisted first-level mental health support  
- Structured escalation during high-risk situations  

> ⚠ Disclaimer: This platform is a first-level emotional support tool and does not provide medical diagnosis or replace professional care.

---

# 🌿 Our Solution – Sahara

Sahara is a privacy-first AI emotional support companion designed to:

- Provide empathetic first-level support
- Recall positive personal memories using a Local RAG system
- Work fully offline (no cloud upload of private chats)
- Support multilingual interaction (Hindi / Marathi / English)
- Detect distress signals and suggest safe escalation

Unlike traditional therapy apps, Sahara focuses on:

- 🧠 On-device AI processing  
- 🏠 Local memory storage  
- 🌏 Cultural context sensitivity  
- 🔐 Ethical safeguards  
- 🚨 Crisis keyword detection  

---

# 🧠 Phase 1 – Local RAG Backend (Current Build)

### Implemented:

- WhatsApp chat export parsing  
- Semantic chunking (size=5, stride=3)  
- Embedding via Sentence Transformers  
- Local vector storage using ChromaDB  
- Semantic retrieval of relevant memory snippets  

This enables Sahara to recall emotionally relevant personal memories and ground responses in user context.

---

# 💬 Phase 2 – Memory-Aware Emotional Chat (UI Built)

Frontend interface includes:

- RAG memory search panel
- LLM-style emotional chat simulation
- Crisis keyword detection logic
- Session timer (20-minute ethical cap)
- Memory score visibility
- Suggested emotional prompts

---

# 🎙 Phase 3 – Voice Distress Analysis (Planned)

- Offline Speech-to-Text (VOSK)
- Prosodic feature analysis (pitch, energy, speech rate)
- Distress scoring
- Escalation logic with Indian helplines

---

# 🛠 Tech Stack

Backend:
- Python 3.11
- Sentence-Transformers
- ChromaDB
- PyTorch
- Local Persistent Vector Database

Frontend:
- HTML / CSS / JavaScript
- Fully client-side UI
- Privacy-first architecture

---

# ⚙ Setup

```bash
py -3.11 -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# 🌿 Sahara — Grief & Loneliness Companion App

> *बनाया गया प्यार से* — Built with love  
> Team **GlitchInnovators** · Hackathon Project · 2026

---

## What is Sahara?

Sahara is a mobile grief companion app that uses on-device AI to help users process loss. It lets you import WhatsApp conversations with a deceased loved one and have meaningful, memory-driven conversations — privately, gently, and with care.

---

## Features

### 💬 AI Memory Chat
Import a WhatsApp `.txt` export and ask questions like *"What did Aai say about cooking?"* — powered by RAG (Retrieval-Augmented Generation) with local LLM inference. Everything stays on your device.

### 🎙️ Voice Queries
Speak your query in **Hindi or English**. Transcribed locally using Vosk — no cloud, no data leaving your phone.

### 📓 Journal
A private grief diary. Write freely. No one else can read it.

### 🌙 Aasman (आसमान) — The Evening Gathering
An anonymous collective ritual space, open every night at **8 PM IST**:
- **Sky** — See tonight's diya count, whisper count, and a moon countdown to the ritual
- **Diya Wall** — Light a virtual diya with a colour and intention (one per day)
- **Whispers** — Send an anonymous 120-character message into the night; echo others' whispers
- **Ritual** — A guided breathing exercise (4s inhale · 2s hold · 6s exhale) with a shared reflection prompt

### 🪑 Baithak (बैठक) — Peer Support Forum
An anonymous peer support space:
- 12 rotating symbol identities (🌿 Banyan, 🌊 River, 🪨 Stone, and more)
- Post under categories: Grief & Loss, Anxiety, Loneliness, Anger, Burnout, and more
- Threads auto-archive after 7 days
- Trained volunteer responses
- Crisis helpline resources always visible

### 🔒 Privacy & Lock Screen
Face ID / biometric lock screen simulation. Encrypted local storage. No accounts, no sign-up.

---

## Tech Stack

### Frontend — Flutter
| Package | Purpose |
|---|---|
| Flutter 3.19.6 (Dart) | Cross-platform UI |
| Provider | State management |
| flutter_secure_storage | Encrypted on-device storage |
| local_auth | Biometrics / Face ID |
| http | API calls |
| file_picker | WhatsApp `.txt` import |
| record + audioplayers | Voice recording & playback |
| socket_io_client | Real-time Aasman updates |

### Backend — Python Flask
| File | Purpose |
|---|---|
| `app.py` | Main Flask server (port 5000) |
| `phase1_rag.py` | ChromaDB vector store + sentence-transformers |
| `phase2_llm.py` | LLM inference (Phi-3-mini GGUF) |
| `phase3_voice.py` | Vosk voice transcription (Hindi + English) |
| `aasman_backend.py` | Aasman real-time backend — Flask + Firebase + Socket.IO (port 5001) |

---

## Project Structure

```
integrated/integrated/
├── sahara_flutter/
│   └── lib/
│       ├── main.dart
│       ├── models/models.dart
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── chat_screen.dart
│       │   ├── journal_screen.dart
│       │   ├── lock_screen.dart
│       │   ├── onboarding_screen.dart
│       │   ├── settings_screen.dart
│       │   ├── aasman/
│       │   │   └── aasman_hub.dart        ← Sky, Diya, Whisper, Ritual
│       │   └── baithak/
│       │       └── baithak_screen.dart    ← Peer support forum
│       ├── services/
│       │   ├── api_service.dart
│       │   ├── app_state.dart
│       │   ├── biometric_service.dart
│       │   └── aasman_service.dart        ← Socket.IO + HTTP + data models
│       ├── theme/sahara_theme.dart
│       └── widgets/
│           ├── auth_gate.dart
│           └── widgets.dart
└── sahara_backend/
    ├── app.py
    ├── phase1_rag.py
    ├── phase2_llm.py
    ├── phase3_voice.py
    ├── aasman_backend.py
    └── requirements.txt
```

---

## Running the Project

### Prerequisites
- Flutter 3.19.6
- Python 3.10+
- Phi-3-mini-4k-instruct-q4.gguf (~2GB) from HuggingFace
- Vosk Hindi + English-IN models from [alphacephei.com/vosk/models](https://alphacephei.com/vosk/models)

### Terminal 1 — Main Backend (port 5000)
```bash
cd sahara_backend
python app.py
```

### Terminal 2 — Aasman Backend (port 5001)
```bash
cd sahara_backend
python aasman_backend.py
```

### Terminal 3 — Flutter App
```bash
cd sahara_flutter
flutter pub get
flutter run -d chrome
```

---

## API Endpoints

### Port 5000 — Main Sahara Backend
| Method | Endpoint | Description |
|---|---|---|
| POST | `/import` | Upload WhatsApp `.txt` chat file |
| POST | `/generate` | Text query to LLM `{"query": "..."}` |
| POST | `/voice_query` | Voice audio → transcription + LLM |
| GET | `/health` | Status check |

### Port 5001 — Aasman Backend
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/sky` | Stats: diya count, whisper count, ritual info |
| POST | `/api/diyas` | Light a diya (color, intent) |
| GET | `/api/whispers` | Get today's whispers |
| POST | `/api/whispers` | Send a whisper (120 char max) |
| POST | `/api/whispers/:id/echo` | Echo a whisper |
| GET | `/api/ritual` | Ritual info + participant count |
| POST | `/api/ritual/join` | Join evening ritual |

**Socket.IO events:** `diya_lit` · `new_whisper` · `ritual_participant_count`

---

## Crisis Resources

Baithak always displays these helplines:

| Organisation | Number |
|---|---|
| iCall | 9152987821 |
| Vandrevala Foundation | 9999666555 |
| AASRA | 9820466627 |

---

## Firebase Setup (for Aasman real-time)

1. Create project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Realtime Database
3. Download `serviceAccountKey.json` → place in `sahara_backend/`
4. Create `.env` in `sahara_backend/`:
```
FIREBASE_DB_URL=https://your-project.firebaseio.com
```

---

## Git History

```
✔ Sahara v1.0 - Flutter + Python backend integrated
✔ Remove exposed secrets and DB files
✔ Fix gitignore - exclude DB, models and voice files
✔ Add Aasman + Baithak features to Sahara
✔ Fix gitignore - exclude Chrome cache and browser data files
```

---

## Team GlitchInnovators

Built for a hackathon with 💛 — Sahara means *support* in Arabic and *desert* in Hindi. A place that holds you even in the vast, lonely stretches.
