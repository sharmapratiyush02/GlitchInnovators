# 🌿 Sahara — Private AI Grief Companion

> Replies as your loved one, in their exact voice, words, and style.

---

## What It Does

Upload a WhatsApp chat export. Sahara analyzes the loved one's writing —
their endearments, vocabulary, emoji, punctuation, language blend — and
responds to your messages **as them**, using their real words.

---

## Project Structure

```
sahara/
├── backend/           # FastAPI Python backend
│   ├── main.py        # All API routes + AI logic
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/          # React + Vite + Tailwind frontend
│   ├── src/
│   │   ├── pages/     # LandingPage, UploadPage, ChatPage, MemoriesPage
│   │   ├── components/# AppShell (sidebar + nav)
│   │   └── utils/     # api.js (Axios client)
│   ├── Dockerfile
│   └── nginx.conf
├── docker-compose.yml # One-command full-stack deploy
└── .env.example       # Copy to .env, add your API key
```

---

## Option 1 — Run Locally (Fastest)

### Prerequisites
- Python 3.11+
- Node.js 18+
- (Optional) Anthropic API key for Claude-powered replies

### Backend
```bash
cd backend
pip install -r requirements.txt

# Copy and edit env
cp ../.env.example .env
# Add ANTHROPIC_API_KEY=sk-ant-...

python main.py
# Runs on http://localhost:8000
```

### Frontend
```bash
cd frontend
npm install

# Point at local backend
echo "VITE_API_URL=http://localhost:8000" > .env

npm run dev
# Opens at http://localhost:3000
```

---

## Option 2 — Docker (One Command)

```bash
# 1. Copy env and add your API key
cp .env.example .env
nano .env   # Add ANTHROPIC_API_KEY

# 2. Start everything
docker-compose up --build

# App:     http://localhost:3000
# API:     http://localhost:8000
# API docs: http://localhost:8000/docs
```

---

## Option 3 — Deploy to Render.com (Free Tier)

### Backend (Web Service)
1. Push to GitHub
2. New Web Service → connect repo → select `backend/` as root
3. Build: `pip install -r requirements.txt`
4. Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add env vars: `ANTHROPIC_API_KEY`, `JWT_SECRET`
6. Note the URL: `https://sahara-backend.onrender.com`

### Frontend (Static Site)
1. New Static Site → connect repo → select `frontend/` as root
2. Build: `npm install && npm run build`
3. Publish dir: `dist`
4. Add env: `VITE_API_URL=https://sahara-backend.onrender.com`

---

## Option 4 — Deploy to Railway

```bash
# Install Railway CLI
npm install -g @railway/cli
railway login

# Deploy backend
cd backend
railway init
railway up

# Set env vars
railway variables set ANTHROPIC_API_KEY=sk-ant-...
railway variables set JWT_SECRET=your-secret

# Deploy frontend
cd ../frontend
railway init
railway up
```

---

## Option 5 — Deploy to Fly.io

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Backend
cd backend
fly launch --name sahara-backend
fly secrets set ANTHROPIC_API_KEY=sk-ant-...
fly deploy

# Frontend  
cd ../frontend
fly launch --name sahara-frontend
fly deploy
```

---

## API Endpoints

| Method | Path                    | Description                        |
|--------|-------------------------|------------------------------------|
| GET    | `/health`               | Health check + status              |
| POST   | `/upload`               | Upload `_chat.txt`, returns session|
| POST   | `/chat`                 | Send message, get reply as person  |
| GET    | `/session/{id}`         | Get session info                   |
| GET    | `/memories/{id}`        | List/search indexed memories       |
| DELETE | `/session/{id}`         | Delete session + all memories      |

### Chat Request
```json
POST /chat
{
  "message": "I miss you so much today",
  "session_id": "uuid-from-upload"
}
```

### Chat Response
```json
{
  "reply": "Beta,\n\nKhana kha lena aaj...",
  "is_crisis": false,
  "memories_used": 3,
  "person_name": "Aai"
}
```

---

## How the AI Reply Works

1. **Profile built** from the loved one's messages:
   - Endearments used (beta, jaan, dikra…)
   - Opening/closing words they repeated
   - Hindi/Marathi/English language blend
   - Emoji they used and where they placed them
   - Punctuation style (!, …, .)
   - Signature phrases (2+ word sequences repeated)

2. **Most relevant memory** retrieved via ChromaDB semantic search

3. **Claude prompted** with a system prompt that says:
   *"You are {name}. Here are their real messages. Reply as them."*

4. **Reply returned** in their exact voice — with their endearments,
   their language, their emoji, signed off as them.

---

## Without Anthropic API Key

The app still works — it uses a rule-based fallback that:
- Opens with their real endearments
- Uses their actual sampled messages as the core reply
- Applies their emoji and punctuation style
- Signs off as them

---

## Safety

- Crisis keywords trigger immediate helpline display — no AI reply
- Hard-coded helplines: iCall, AASRA, Vandrevala Foundation
- Disclaimer shown after every AI message
- Sessions stored in-memory only (add Redis for persistence)

---

## Crisis Helplines (Always Shown)

| Service | Number |
|---------|--------|
| iCall (Tata Institute) | 9152987821 |
| AASRA | 9820466726 |
| Vandrevala Foundation | 9999666555 |

---

Built with care at NAVONMESH Hackathon 2026 · Team Sahara 🌿
