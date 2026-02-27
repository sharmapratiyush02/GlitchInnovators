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
