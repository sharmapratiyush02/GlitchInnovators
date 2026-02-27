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