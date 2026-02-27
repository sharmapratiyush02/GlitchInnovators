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

## 🌿 Our Solution – Sahara

Sahara is a privacy-first AI emotional support companion designed to:

- Provide empathetic first-level support
- Recall positive personal memories (local RAG system)
- Work fully offline (no cloud upload of private chats)
- Support multilingual interaction
- Detect distress signals and suggest safe escalation

Unlike traditional therapy apps, Sahara focuses on:
- On-device AI
- Cultural context sensitivity
- Memory-aware emotional support
- Ethical safeguards

---

## 🧠 Phase 1 – Local RAG Backend (Current Build)

Implemented:

- WhatsApp chat export parsing
- Semantic chunking (size=5, stride=3)
- Embedding via Sentence Transformers
- Local vector storage using ChromaDB
- Semantic retrieval of relevant memory snippets

---

## 🛠 Tech Stack

- Python 3.11
- Sentence-Transformers
- ChromaDB
- PyTorch
- Local Persistent Vector Database
- Modular CLI-based RAG Engine

---

## ⚙ Setup

```bash
py -3.11 -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

---

## ▶ Usage

### Ingest Chat File
```bash
python rag.py ingest your_chat.txt
```

### Query Memory
```bash
python rag.py query "Missing Aai today"
```

---

## 🔐 Privacy & Ethics

- Fully local vector database
- No personal data sent to external APIs
- Clear disclaimers
- Designed as support tool only
- No medical claims

---

## ⏳ Hackathon Progress Log

- [x] Hour 1 – Environment setup & backend dependencies
- [ ] Hour 2 – Test ingestion pipeline
- [ ] Hour 3 – Improve retrieval scoring
- [ ] Hour 4 – Add response generation layer
- [ ] Hour 5+ – UI & Voice Integration
- [ ] Final – Demo + PPT + Deployment

---

Built with responsibility, empathy, and privacy-first design.