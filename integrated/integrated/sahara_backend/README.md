# Sahara Backend

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Download LLM model (phi-3-mini quantized, ~2GB)
mkdir -p models
# Download from: https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf
# Place as: models/phi-3-mini-4k-instruct-q4.gguf

# 3. Download Vosk speech models
mkdir -p vosk_models
# Hindi:  https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip
# En-IN:  https://alphacephei.com/vosk/models/vosk-model-small-en-in-0.4.zip
# Unzip both into vosk_models/

# 4. Start server
python app.py
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Server + model status |
| POST | `/import` | Upload WhatsApp `_chat.txt` (field: `chat_file`) |
| POST | `/generate` | Text query → LLM response (JSON: `{"query": "..."}`) |
| POST | `/voice_query` | Voice audio → transcribe → LLM (multipart: `audio` field) |

## Flutter Connection

In `lib/services/api_service.dart`, set `_baseUrl`:

- **Android Emulator:** `http://10.0.2.2:5000`
- **Physical device (USB debug):** `http://<your_laptop_ip>:5000`
- **iOS Simulator:** `http://localhost:5000`

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_MODEL_PATH` | `./models/phi-3-mini-4k-instruct-q4.gguf` | Path to GGUF model |
| `LLM_THREADS` | `4` | CPU threads for inference |
| `LLM_GPU_LAYERS` | `0` | GPU layers (0 = CPU only) |
| `VOSK_HI` | `./vosk_models/vosk-model-small-hi-0.22` | Hindi Vosk model path |
| `VOSK_EN_IN` | `./vosk_models/vosk-model-small-en-in-0.4` | English-IN Vosk model path |


🌿 Sahara — AI Grief Companion

Sahara is a privacy-first AI grief companion built with Flutter + Python Flask.

It helps users feel less alone by retrieving meaningful memories from their own WhatsApp chats and responding with empathy using an on-device LLM.

🌿 Current Progress (MVP Status)
✅ Completed

Flutter UI (Home, Chat, Journal, Aasman, Baithak)

WhatsApp chat import (_chat.txt)

Numpy-based local vector store (ChromaDB removed)

Semantic memory retrieval (SentenceTransformers)

Flask backend fully integrated

LLM integration (Phi-3-mini GGUF via llama-cpp)

Safe fallback mode (works even without LLM)

Crisis keyword detection guardrail

Voice pipeline (Vosk STT + distress detection)

CORS enabled (Flutter Web compatible)

Python 3.14 compatible

🔄 In Progress

LLM response quality tuning

Distress detection calibration

UI polish & animations

Model performance optimization

⏳ Optional Future Enhancements

Cloud deployment (Render / Railway / Azure)

Streaming LLM responses

Docker containerization

Memory deletion & re-indexing

Firebase-powered community backend

🧠 Architecture Overview

Flutter (Frontend)
↓
Flask Backend (app.py)
↓
SentenceTransformer → Vector Store (pickle + numpy)
↓
Phi-3-mini GGUF (llama-cpp-python)
↓
Optional Voice: Vosk STT + librosa distress detection

Everything runs locally. No cloud database required.

🚀 Quick Start
# 1. Install dependencies
pip install -r requirements.txt

# 2. Download LLM model (~2GB)
mkdir models
# Download from:
# https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf
# Place as:
models/phi-3-mini-4k-instruct-q4.gguf

# 3. (Optional) Download Vosk speech models
mkdir vosk_models
# Hindi:
# https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip
# English-IN:
# https://alphacephei.com/vosk/models/vosk-model-small-en-in-0.4.zip
# Unzip into vosk_models/

# 4. Start server
python app.py

Backend runs at:

http://localhost:5000
📡 API Endpoints
Method	Endpoint	Description
GET	/health	Backend status
POST	/import	Upload WhatsApp _chat.txt (field: chat_file)
POST	/generate	Text query → AI response
POST	/voice_query	Voice audio → STT → AI
📱 Flutter Connection

In:

lib/services/api_service.dart

Set _baseUrl depending on platform:

Android Emulator:

http://10.0.2.2:5000

Physical Android device:

http://<your_laptop_ip>:5000

iOS Simulator:

http://localhost:5000
🔐 Environment Variables (Optional)
Variable	Default	Description
LLM_MODEL_PATH	./models/phi-3-mini-4k-instruct-q4.gguf	Model path
LLM_THREADS	4	CPU threads
LLM_GPU_LAYERS	0	GPU layers
VOSK_HI	./vosk_models/vosk-model-small-hi-0.22	Hindi STT model
VOSK_EN_IN	./vosk_models/vosk-model-small-en-in-0.4	English-IN STT
🛡 Safety Guardrails

Crisis keyword detection

Self-harm prevention response override

Never impersonates deceased loved ones

Never invents memories

Always includes professional help disclaimer

🗂 Project Structure
sahara_backend/
  app.py
  models/
  vosk_models/
  sahara_vectors.pkl

sahara_flutter/
  lib/
    screens/
    services/
🧪 Demo Flow

Import WhatsApp chat

Ask: “Missing Aai today”

Sahara retrieves memory

LLM responds gently

Crisis keywords trigger emergency override

🌿 Philosophy

Sahara is not a therapist.
It is a memory-anchored companion designed to gently reflect warmth from the user’s own past.

All data stays local.