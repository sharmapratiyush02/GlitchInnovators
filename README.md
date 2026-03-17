# 🌿 Sahara – Privacy-First Mental Health Support Companion

> *"When grief is too heavy to carry alone, Sahara remembers for you."*

**Problem Code:** 26001 – Mental Health Support Apps

---

## 📌 Table of Contents

1. [Problem Statement](#-problem-statement)
2. [Our Solution – Sahara](#-our-solution--sahara)
3. [The Three Pillars](#-the-three-pillars)
4. [How Sahara Works — Core User Flow](#-how-sahara-works--core-user-flow)
5. [Tech Stack](#️-tech-stack)
6. [Project Phases](#-project-phases)
7. [Team Roles & Responsibilities](#-team-roles--responsibilities)
8. [Pratyush Bhaiya — Complete Task Guide](#-pratyush-bhaiya--complete-task-guide)
9. [Play Store Launch Checklist](#-play-store-launch-checklist)
10. [Play Store Listing Copy](#-play-store-listing-copy)
11. [Data Safety & Privacy](#-data-safety--privacy)
12. [Android Technical Requirements](#️-android-technical-requirements)
13. [3-Week Launch Sprint](#-3-week-launch-sprint)
14. [Crisis Support Helplines](#-crisis-support-helplines)
15. [Setup](#️-setup)
16. [Disclaimer](#️-disclaimer)

---

## 🧩 Problem Statement

India is in a silent grief and mental health crisis. Rapid urbanisation has physically separated millions of families. Young professionals move to cities while parents remain in villages. When a loved one passes away, grief is compounded by distance, cultural stigma, and a near-total absence of affordable, private support.

| The Reality in India | Why Existing Apps Fail |
|---|---|
| 150 million+ Indians need mental health support | All require internet accounts — privacy fears block use |
| Fewer than 1 psychiatrist per 100,000 people | Generic CBT responses with no cultural sensitivity |
| ~83% avoid therapy due to stigma (iCall Survey) | English-only or limited Hindi, no Marathi support |
| ~62% of Indians lose a parent before age 40 | Cannot recall your loved one's actual words or jokes |
| 500M+ WhatsApp users — years of saved memories | Subscriptions cost ₹600–1200/month — unaffordable |

This project aims to design an innovative, scalable, and accessible digital support system that enables:

- Early emotional distress detection
- Anonymous and privacy-sensitive interaction
- Multilingual accessibility (Hindi / Marathi / English)
- AI-assisted first-level mental health support
- Structured escalation during high-risk situations

> ⚠️ **Disclaimer:** This platform is a first-level emotional support tool and does not provide medical diagnosis or replace professional care.

---

## 🌿 Our Solution – Sahara

Sahara is a **privacy-first, on-device AI grief companion** designed to:

- Provide empathetic first-level support
- Recall positive personal memories using a **Local RAG system**
- Work **fully offline** (no cloud upload of private chats)
- Support **multilingual interaction** (Hindi / Marathi / English)
- Detect distress signals and suggest safe escalation

Unlike traditional therapy apps, Sahara focuses on:

- 🧠 **On-device AI processing** — no data leaves your phone
- 🏠 **Local memory storage** — WhatsApp memories stay private
- 🌏 **Cultural context sensitivity** — built for India
- 🔐 **Ethical safeguards** — no impersonation, no dependency loops
- 🚨 **Crisis keyword detection** — always shows helplines when needed

---

## 🌟 The Three Pillars

| 🌿 Sahara Core | 🌌 Aasman (आसमान) | 🪑 Baithak (बैठक) |
|---|---|---|
| Private AI companion. Reads WhatsApp exports. Recalls real memories. Speaks Hindi, Marathi, English. Runs 100% offline. | Anonymous community sky. Light a diya. Release a whisper. Join a nightly breathing ritual at 8PM IST. Feel less alone without speaking. | Peer support forum. Post anonymously. A trained volunteer responds within 24 hours. Threads auto-delete after 7 days. |

---

## 🔄 How Sahara Works — Core User Flow

| Step | What Happens | Where It Happens |
|---|---|---|
| 1 | User exports WhatsApp chat with a deceased loved one and uploads to Sahara | On-device only. Parsed locally, temp file deleted immediately. |
| 2 | Sahara converts every message into a searchable memory using multilingual AI embeddings | Embeddings stored in local ChromaDB vector database. Never transmitted. |
| 3 | User says or types: "I miss Aai so much today" in Hindi, Marathi, or English | Voice processed on-device via Vosk STT. No audio ever sent to any server. |
| 4 | Sahara retrieves the most relevant real memories — a festival joke, a small kindness, a shared moment | Cosine similarity search in local vector store. Sub-100ms retrieval. |
| 5 | A locally-running LLM crafts a warm, culturally aware response referencing the real memory | Quantized model (Phi-3 Mini or Gemma-2B) runs on phone CPU/NPU. No cloud API call. |
| 6 | If crisis keywords or voice distress are detected, Sahara immediately shows helplines and stops | Three-layer safety: text keywords → acoustic distress score → content moderation. |

---

## 🛠️ Tech Stack

**Backend (On-Device Python Pipeline):**
- Python 3.11
- Sentence-Transformers (multilingual embeddings)
- ChromaDB (local persistent vector database)
- PyTorch
- Flask (local HTTP bridge on localhost:5005/5006/5007)
- Vosk (offline Speech-to-Text)
- librosa (prosodic voice distress analysis)
- Phi-3 Mini / Gemma-2B Q4 (quantized on-device LLM)

**Mobile Frontend:**
- Flutter (cross-platform, Android-first)
- Chaquopy (Python 3.11 runtime embedded in Android)
- Play Asset Delivery (LLM model delivery)

**Community Backend (Aasman + Baithak):**
- FastAPI + PostgreSQL (Baithak peer support)
- Google Cloud Run (auto-scaling deployment)
- Redis / Upstash (rate limiting)
- Firebase Crashlytics (crash monitoring)
- pg_cron (7-day auto-archive)

**Privacy Architecture:**
- Fully client-side UI — HTML / CSS / JavaScript (Phase 2 prototype)
- No accounts, no cloud analytics, no ad tracking
- DPDP Act 2023 compliant

---

## 🚀 Project Phases

### Phase 1 — Local RAG Backend ✅ (Current Build)

- WhatsApp chat export parsing
- Semantic chunking (size=5, stride=3)
- Embedding via Sentence Transformers
- Local vector storage using ChromaDB
- Semantic retrieval of relevant memory snippets

This enables Sahara to recall emotionally relevant personal memories and ground responses in user context.

### Phase 2 — Memory-Aware Emotional Chat ✅ (UI Built)

Frontend interface includes:
- RAG memory search panel
- LLM-style emotional chat simulation
- Crisis keyword detection logic
- Session timer (20-minute ethical cap)
- Memory score visibility
- Suggested emotional prompts

### Phase 3 — Voice Distress Analysis 🔲 (Planned)

- Offline Speech-to-Text (VOSK)
- Prosodic feature analysis (pitch, energy, speech rate)
- Distress scoring
- Escalation logic with Indian helplines

---

## 👥 Team Roles & Responsibilities

Sahara is built by a four-person team. Each member owns a distinct domain.

| Aanya | Pradyumna | Raj | Pratiyush |
|---|---|---|---|
| Team Lead · Flutter · Backend | Android · Build · Pipeline | Backend · Compliance · DevOps | Localisation · QA · Content |

### Aanya — Team Lead · Flutter Engineer · Backend Architect

Aanya owns the product end-to-end. She is responsible for the Flutter mobile app, wiring the on-device Python RAG and LLM pipeline into production, the Play Store submission, and coordinating the final launch sprint. As Team Lead she is the single point of accountability for the app going live.

Core responsibilities: Flutter app architecture, Chaquopy integration, Play Store submission, Play Console listing, Privacy Policy hosting, Aasman production backend (Cloud Run), DPDP consent screen, final build sign-off.

### Pradyumna — Android Engineer · Build Pipeline · On-Device AI

Taher owns the Android build layer — everything between the Flutter/Python code and a working AAB that passes Play Store review. He owns LLM packaging, Chaquopy embedding, and all technical compliance requirements from Google.

Core responsibilities: AAB build pipeline, Chaquopy + Python dependencies, LLM packaging via Play Asset Delivery, Target SDK 35, 64-bit ABI, permission audit, face auth module, ProGuard rules, performance profiling.

### Raj — Backend Engineer · DevOps · Legal Compliance

Raj owns the server-side infrastructure and all compliance obligations. He ensures Aasman and Baithak run reliably in production and that Sahara meets India's DPDP Act 2023 requirements before going live.

Core responsibilities: Aasman Cloud Run deployment, Redis rate limiting, Baithak FastAPI + PostgreSQL, Firebase security rules audit, DPDP Act compliance review, crisis helpline verification, nightly purge cron jobs, server monitoring.

---

## 📋 Pratiyush — Complete Task Guide

**Role:** Localisation · QA · Content & UX Writing

Pratyush owns everything the user reads, hears, and experiences — in all three languages. He ensures Sahara speaks to a grieving person in Maharashtra with the right words, the right tone, and the right cultural sensitivity. He also owns QA: real device testing across diverse user types before the app reaches the Play Store.

---

### 🗓️ Project Timeline — 3-Week Sprint

| Week | Tasks |
|---|---|
| **Week 1** | Write Terms of Service document · Translate Flutter UI strings to Hindi and Marathi |
| **Week 2** | Write onboarding copy · Prepare Play Store screenshots · Create promotional video · Translate Play Store listing copy |
| **Week 3** | Conduct QA testing with real users · Perform accessibility audit · Document edge cases and parser failures · Prepare QA report |

---

### Phase 1 — Terms of Service (Play Store Requirement)

**Steps:**
1. Create a document titled **"SAHARA Terms of Service"**
2. Write the following sections:

   - **Introduction** — Explain that Sahara is a private AI grief companion that runs locally on the user's phone
   - **User Responsibility** — Users must upload chats responsibly and only with consent
   - **Privacy Notice** — Chats and voice remain on the device and are never uploaded
   - **DPDP Compliance** — Include: *"We follow India's Digital Personal Data Protection (DPDP) Act 2023 to ensure users maintain control of their personal memories."*
   - **Medical Disclaimer** — State clearly that Sahara is not therapy or medical advice
   - **Crisis Support Section** — Include verified helpline numbers (iCall, Vandrevala, AASRA, SNEHI)

> ⚠️ **Important:** Call each helpline number once to verify it is active before publishing.

3. Export the document as **PDF** and upload to a public URL (Google Drive, Notion, or website)

---

### Phase 2 — Flutter Localisation (Hindi & Marathi)

1. Request the English Flutter string file (`app_en.arb`) from the developer
2. Create two new files: `app_hi.arb` and `app_mr.arb`
3. Translate all UI text. Example:

| English | Hindi | Marathi |
|---|---|---|
| Upload WhatsApp Chat | व्हाट्सऐप चैट अपलोड करें | व्हॉट्सअॅप चॅट अपलोड करा |

4. Ask a **native Marathi speaker** to review all Marathi translations
5. Send final translation files to the developer

> ❌ Do NOT use machine translation for the final version.

---

### Phase 3 — Onboarding UX Copy

Write empathetic, stigma-free onboarding text for each screen:

| Screen | Copy |
|---|---|
| **Welcome Screen** | "Welcome to Sahara. A private place where memories stay safely on your phone." |
| **Face Registration Screen** | "This quick face scan keeps your memories private, like a family lock." |
| **Chat Upload Screen** | "Export a WhatsApp chat with someone you loved. Sahara will quietly remember those moments." |
| **Privacy Screen** | "Your chats never leave your phone. Sahara works offline." |
| **Language Selection Screen** | "Choose the language that feels most comfortable for you." |

---

### Phase 4 — Play Store Screenshots

Capture screenshots of the app on a phone for these **required screens:**
- Home screen
- Chat screen
- Memory recall response
- Breathing exercise
- Aasman community screen

**Create versions for:** English · Hindi · Marathi

- Use **Canva** to design Play Store images at **1080 × 1920 px**
- Ensure at least **2 screenshots per language** for regional Play Store listings
- Coordinate with the team lead for: App icon (512×512 PNG) and Feature graphic (1024×500 PNG)

---

### Phase 5 — Promotional Video (Play Store)

Record a **30–90 second** demo video showing this flow:
1. Open Sahara
2. Upload WhatsApp chat
3. Type: *"I miss Aai today"*
4. AI memory response appears
5. Breathing exercise screen

**Tools:** AZ Screen Recorder or OBS. Export for Play Store listing.

---

### Phase 6 — QA Testing with Real Users

Test the app with **10 real users** using:
- Real WhatsApp chat exports
- At least **3 device types** (e.g., Redmi Note 12, Samsung Galaxy A14, Pixel)

Each tester should: export chat → upload chat → ask *"I miss my father today"*

Document all issues in a table:

| Problem | Device | Edge Case | Steps to Reproduce |
|---|---|---|---|
| Chat not loading | Redmi Note 12 | Large emoji messages | Upload old chat with emojis |

**Focus especially on:**
- Parser failures
- Emoji parsing issues
- Very old chat formats
- Large chat files (>100MB)

---

### Phase 7 — Accessibility Audit

Check the following accessibility requirements:
- Font scaling works properly across all screens
- Buttons have minimum **48dp touch size**
- Text contrast ratios are readable
- **Android TalkBack** reads all screens correctly

---

### Phase 8 — Translate Play Store Listing

Manually translate the Play Store listing content into Hindi and Marathi.

**Title (max 30 characters):**

| Language | Title |
|---|---|
| English | Sahara – Your Private Grief Companion |
| Hindi | सहारा – आपका निजी साथी |
| Marathi | सहारा – तुमचा खाजगी साथी |

**Short Description** (< 80 characters): Translate naturally — no machine translation.

**Full Description:** Translate these sections: Introduction · What Sahara Does · What Sahara Will Never Do · Crisis Support

> ❌ Do NOT use machine translation. Ensure cultural tone is correct and sensitive.

---

### Phase 9 — In-App Feedback Mechanism

Design a feedback prompt after the user's **third session:**

> **"How did Sahara help you today?"**
> Rating: ⭐⭐⭐⭐⭐ (1–5 stars)

- Feedback must be **anonymous**
- Results sent to a private Google Sheet maintained by the team
- Provide the text and design to the Flutter developer for implementation

---

### ✅ Pratyush's Final Deliverables Checklist

| # | Deliverable | Status |
|---|---|---|
| 1 | Terms of Service PDF (hosted at public URL) | 🔲 Pending |
| 2 | Hindi translation file (`app_hi.arb`) | 🔲 Pending |
| 3 | Marathi translation file (`app_mr.arb`) — native speaker reviewed | 🔲 Pending |
| 4 | Onboarding UX copy (all 5 screens) | 🔲 Pending |
| 5 | Play Store screenshots (English + Hindi + Marathi) | 🔲 Pending |
| 6 | Promotional video (30–90 seconds) | 🔲 Pending |
| 7 | QA testing report (10 users, 3 devices) | 🔲 Pending |
| 8 | Play Store listing translations (Title + Short + Full Description) | 🔲 Pending |
| 9 | In-app feedback mechanism design | 🔲 Pending |

---

## 📋 Play Store Launch Checklist

Every item below must be completed before submitting to the Play Store. Aanya is the final approver on all submission items.

| Requirement | Owner | Status |
|---|---|---|
| App signed with release keystore (upload key + app signing enrolled) | Aanya | 🔲 Pending |
| Android App Bundle (.aab) build — APK not accepted for new apps | Taher Ali | 🔲 Pending |
| Target API level 35 (Android 15) | Taher Ali | 🔲 Pending |
| 64-bit ABI support (arm64-v8a required) | Taher Ali | 🔲 Pending |
| Privacy Policy at hosted public URL | Aanya | 🔲 Pending |
| **Terms of Service at hosted public URL** | **Pratyush Bhaiya** | 🔲 Pending |
| Data Safety form completed in Play Console | Aanya | 🔲 Pending |
| IARC content rating questionnaire completed | Aanya | 🔲 Pending |
| App icon: 512×512 PNG, no alpha channel | Aanya | 🔲 Pending |
| Feature graphic: 1024×500 PNG | Aanya | 🔲 Pending |
| **Minimum 2 phone screenshots per language** | **Pratyush Bhaiya** | 🔲 Pending |
| App does NOT use MANAGE_EXTERNAL_STORAGE permission | Taher Ali | 🔲 Pending |
| Microphone permission rationale dialog implemented | Taher Ali | 🔲 Pending |
| All 4 crisis helpline numbers verified active | Raj Bhaiya | 🔲 Pending |
| DPDP Act 2023 consent screen on first launch | Aanya + Raj | 🔲 Pending |
| Firebase Crashlytics integrated before internal test | Aanya | 🔲 Pending |
| Internal test track release successful (0 crashes) | Aanya | 🔲 Pending |

---

## 📝 Play Store Listing Copy

**App Title (30 characters max):**
> Sahara – Your Private Grief Companion

**Short Description (80 characters):**
> A private, on-device AI companion that remembers your loved ones. No data uploaded. Ever.

**Full Description:**

Sahara is a grief companion unlike anything else on the Play Store.

It works entirely on your phone — no account, no server, no internet required after setup. Sahara reads your WhatsApp chat exports and remembers the real words, jokes, and moments you shared with people you have lost. When grief overwhelms you, it reflects those memories back with warmth and cultural understanding in Hindi, Marathi, or English.

Built for India. Works offline. Free forever.

**WHAT SAHARA DOES:**
- Reads your WhatsApp exports and builds a private memory archive — entirely on your device
- When you miss someone, Sahara recalls a real memory: a joke, a festival moment, a small kindness
- Responds in Hindi, Marathi, or English with empathy — never generic advice
- Detects distress in your voice and gently offers breathing exercises
- Connects you to Aasman — an anonymous community where others light a diya tonight
- Gives access to Baithak — peer support from trained volunteers, completely anonymously

**WHAT SAHARA WILL NEVER DO:**
- Upload your chats or voice to any server — ever
- Create an account or track your identity
- Speak as or impersonate your deceased loved one
- Replace a therapist or provide medical advice
- Send push notifications or encourage dependency

**CRISIS SUPPORT — ALWAYS FREE:**
Sahara detects crisis language and immediately shows iCall (9152987821), Vandrevala Foundation (1860-2662-345), and AASRA (9820466627). No account needed. Always visible.

---

## 🔐 Data Safety & Privacy

| Question | Answer |
|---|---|
| Does your app collect or share user data? | Yes — anonymous tokens for Aasman community features only |
| Is all data encrypted in transit? | Yes — HTTPS + Firebase TLS on all Aasman/Baithak endpoints |
| Can users request data deletion? | "Delete All Memories" button in app. Uninstall removes all local data. |
| Personal memories (chat exports) | Stored locally on device only. Never transmitted to any server. |
| Voice audio | Processed on-device only via Vosk STT. Not stored after transcription. |
| Anonymous token (Aasman only) | SHA-256 hash stored server-side. Raw token never leaves device. Purged after 7 days. |
| Diya / Whisper content | Anonymous, no user ID linkage, automatically purged after 7 days. |
| Does app share data with third parties? | No — Firebase is infrastructure only, not used for ads or analytics. |
| Location data collected? | No |
| Financial or health data collected? | No |
| App directed at children under 13? | No — rated 12+ |

---

## ⚙️ Android Technical Requirements

| Requirement | Detail | Owner |
|---|---|---|
| Target SDK | targetSdkVersion 35 (Android 15) | Taher Ali |
| Minimum SDK | minSdkVersion 26 (Android 8.0) — covers 95%+ of India market | Taher Ali |
| Build format | Android App Bundle (.aab) — APK rejected for new apps since Aug 2021 | Taher Ali |
| 64-bit support | arm64-v8a ABI required. x86_64 optional. | Taher Ali |
| File access | Use READ_MEDIA_DOCUMENTS. MANAGE_EXTERNAL_STORAGE triggers Play Store rejection. | Taher Ali |
| Microphone | RECORD_AUDIO — show rationale dialog before requesting | Taher Ali |
| Camera (face auth) | CAMERA — show rationale dialog; explain use case | Taher Ali |
| Python runtime | Chaquopy 15.0+ for embedding Python 3.11 on Android | Taher Ali |
| LLM delivery | Play Asset Delivery (PAD) for Gemma-2B Q4 model files — keeps install < 150MB | Taher Ali |
| App size | Initial install < 150MB. LLM delivered post-install via PAD. | Taher Ali |
| Crash reporting | Firebase Crashlytics — must be integrated before internal test track | Aanya |

---

## 📅 3-Week Launch Sprint

| Week | Aanya (Lead) | Taher Ali | Raj Bhaiya | **Pratyush** |
|---|---|---|---|---|
| **Week 1** | Play Store account, keystore, permissions, privacy policy URL | AAB pipeline, Chaquopy setup, permission audit | Firebase security rules, crisis numbers verified | **Terms of Service, Hindi/Marathi string files** |
| **Week 2** | Flutter integration, onboarding, icon, screenshots, ASO listing | LLM packaging via PAD, 64-bit ABI, face auth | Aasman Cloud Run, Baithak FastAPI, Redis | **Localised screenshots, onboarding copy, promo video** |
| **Week 3** | Internal test track, Crashlytics, Data Safety form, final submission | Performance profiling, ProGuard rules | Monitoring, purge cron, server load test | **10-user QA, accessibility audit** |

---

## 🆘 Crisis Support Helplines

These numbers are embedded in the app and always visible when crisis keywords are detected:

| Helpline | Number |
|---|---|
| iCall | 9152987821 |
| Vandrevala Foundation | +91 9999 666 555 |
| AASRA | +91 22 27546669 |
| SNEHI | +91 9582208181 |

> ⚠️ Raj must verify all four numbers are currently active before Play Store submission.

---

## ⚙️ Setup

```bash
py -3.11 -m venv venv
venv\Scripts\activate
pip install -r requirements.txt