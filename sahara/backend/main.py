# ─────────────────────────────────────────────────────────────
# Sahara — Backend API
# FastAPI + ChromaDB + Sentence Transformers + Anthropic Claude
# ─────────────────────────────────────────────────────────────

import os, re, json, uuid, hashlib
from datetime import datetime, timedelta
from typing import Optional, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, UploadFile, File, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel

import chromadb
from chromadb.config import Settings as ChromaSettings
from sentence_transformers import SentenceTransformer
import anthropic

# ── Config ────────────────────────────────────────────────────
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
JWT_SECRET        = os.getenv("JWT_SECRET", "sahara-secret-change-in-prod")
CHROMA_PATH       = os.getenv("CHROMA_PATH", "./chroma_db")
PORT              = int(os.getenv("PORT", 8000))

CRISIS_KEYWORDS = [
    "suicide","kill myself","end it all","want to die","no point living",
    "can't go on","self harm","hurt myself","आत्महत्या","मर जाना",
    "खत्म करना","जीने का मतलब नहीं","मारना","खुद को नुकसान"
]

HELPLINES = {
    "iCall": "9152987821",
    "AASRA": "9820466726",
    "Vandrevala Foundation": "9999666555",
    "iCall (WhatsApp)": "9152987821"
}

# ── Startup / Shutdown ────────────────────────────────────────
embedder    = None
chroma      = None
collection  = None
ai_client   = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global embedder, chroma, collection, ai_client
    print("Loading embedding model…")
    embedder = SentenceTransformer("all-MiniLM-L6-v2")
    chroma   = chromadb.PersistentClient(path=CHROMA_PATH)
    try:
        collection = chroma.get_collection("sahara_memories")
    except Exception:
        collection = chroma.create_collection("sahara_memories")
    if ANTHROPIC_API_KEY:
        ai_client = anthropic.Anthropic(api_key=ANTHROPIC_API_KEY)
    print("Sahara backend ready ✓")
    yield
    print("Shutting down…")

app = FastAPI(title="Sahara API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer(auto_error=False)

# ── Simple session store (use Redis in prod) ──────────────────
sessions: dict = {}   # token -> { user_id, person_name, created_at }
user_profiles: dict = {}  # user_id -> PersonProfile

# ── Models ────────────────────────────────────────────────────
class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None

class ChatResponse(BaseModel):
    reply: str
    is_crisis: bool
    helplines: Optional[dict] = None
    memories_used: int = 0
    person_name: str = ""

class SessionResponse(BaseModel):
    session_id: str
    person_name: str
    memory_count: int

class UploadResponse(BaseModel):
    session_id: str
    person_name: str
    memory_count: int
    message: str

class PersonProfile(BaseModel):
    name: str = ""
    avg_msg_len: float = 15.0
    uses_emoji: bool = False
    top_emojis: List[str] = []
    endearments: List[str] = []
    signature_phrases: List[str] = []
    mixed_lang: bool = False
    punctuation: str = "."
    opening_words: List[str] = []
    closing_words: List[str] = []
    sample_messages: List[str] = []

# ── Helpers ───────────────────────────────────────────────────
ENDEARMENTS = ["beta","bete","jaan","jaanu","babu","baba","dikra","dikri",
               "pora","pori","munna","munni","laadla","laadli","raja","rani",
               "sona","bachcha","mere bachche","meri jaan","gudiya","yaar","dost"]

HINDI_MARKERS = ["aaj","kal","nahi","bahut","thoda","kuch","sab","ghar","yaad",
                 "khayal","rakhna","kha","pina","aana","jana","raho","rehna",
                 "hai","hain","mera","meri","tumhara","teri","tere","apna",
                 "bilkul","zaroor","jaldi","theek","achha","sunna","chai"]

def detect_crisis(text: str) -> bool:
    t = text.lower()
    return any(kw in t for kw in CRISIS_KEYWORDS)

def parse_whatsapp(text: str) -> list:
    patterns = [
        r'\[(\d{1,2}/\d{1,2}/\d{4}),\s*(\d{1,2}:\d{2}:\d{2}\s*(?:AM|PM))\]\s*(.*?):\s*(.*)',
        r'(\d{1,2}/\d{1,2}/\d{2,4}),\s*(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM))\s*-\s*(.*?):\s*(.*)',
        r'(\d{1,2}/\d{1,2}/\d{2,4}),\s*(\d{1,2}:\d{2})\s*-\s*(.*?):\s*(.*)',
    ]
    messages = []
    for line in text.split('\n'):
        line = line.strip()
        if not line: continue
        for pat in patterns:
            m = re.match(pat, line)
            if m:
                date, time, sender, msg = m.groups()
                if (msg and len(msg) > 3 and
                    'omitted' not in msg.lower() and
                    not msg.startswith('http')):
                    messages.append({
                        "date": date, "time": time,
                        "sender": sender.strip(), "message": msg.strip()
                    })
                break
    return messages

def build_person_profile(messages: list) -> PersonProfile:
    self_rx = re.compile(r'^(me|i|main|mujhe|myself)$', re.I)
    freq = {}
    for m in messages:
        s = m["sender"].strip()
        if not self_rx.match(s):
            freq[s] = freq.get(s, 0) + 1
    if not freq:
        return PersonProfile()
    name = sorted(freq.items(), key=lambda x: -x[1])[0][0]
    their = [m for m in messages if m["sender"] == name and len(m["message"]) > 3]
    if not their:
        return PersonProfile()

    all_text = " ".join(m["message"].lower() for m in their)

    # Endearments
    endearments = [e for e in ENDEARMENTS if e in all_text]

    # Mixed lang
    hindi_count = sum(1 for w in HINDI_MARKERS if w in all_text)
    mixed = hindi_count >= 4

    # Avg length
    avg_len = sum(len(m["message"].split()) for m in their) / len(their)

    # Emoji
    import unicodedata
    emoji_list = []
    for m in their:
        for ch in m["message"]:
            if unicodedata.category(ch) in ('So', 'Sm') or ord(ch) > 0x1F300:
                emoji_list.append(ch)
    ef = {}
    for e in emoji_list: ef[e] = ef.get(e, 0) + 1
    top_emojis = [k for k, _ in sorted(ef.items(), key=lambda x: -x[1])[:6]]

    # Punctuation
    exc = sum(1 for m in their if m["message"].rstrip().endswith('!'))
    ell = sum(1 for m in their if '...' in m["message"])
    if exc > len(their) * 0.3: punct = '!'
    elif ell > len(their) * 0.2: punct = '...'
    else: punct = '.'

    # Opening words
    op_freq = {}
    for m in their:
        w = re.split(r'[\s,!?.]+', m["message"].strip())[0].lower()
        if len(w) > 1: op_freq[w] = op_freq.get(w, 0) + 1
    opening = [k for k, v in sorted(op_freq.items(), key=lambda x: -x[1]) if v > 1][:5]

    # Closing words
    cl_freq = {}
    for m in their:
        words = re.sub(r'[!?.]+$', '', m["message"].strip()).split()
        if words:
            w = words[-1].lower()
            if len(w) > 2: cl_freq[w] = cl_freq.get(w, 0) + 1
    closing = [k for k, v in sorted(cl_freq.items(), key=lambda x: -x[1]) if v > 1][:5]

    # Signature phrases
    phr = {}
    for m in their:
        ws = m["message"].lower().split()
        for i in range(len(ws)-1):
            bi = f"{ws[i]} {ws[i+1]}"
            if len(bi) > 6: phr[bi] = phr.get(bi, 0) + 1
            if i < len(ws)-2:
                tri = f"{bi} {ws[i+2]}"
                if len(tri) > 8: phr[tri] = phr.get(tri, 0) + 1
    sigs = [k for k, v in sorted(phr.items(), key=lambda x: -x[1]) if v >= 2][:10]

    # Sample messages (warm, 4-40 words)
    samples = [m["message"] for m in their
               if 4 <= len(m["message"].split()) <= 40][:30]

    return PersonProfile(
        name=name,
        avg_msg_len=avg_len,
        uses_emoji=len(top_emojis) > 0,
        top_emojis=top_emojis,
        endearments=endearments,
        signature_phrases=sigs,
        mixed_lang=mixed,
        punctuation=punct,
        opening_words=opening,
        closing_words=closing,
        sample_messages=samples,
    )

def build_system_prompt(profile: PersonProfile) -> str:
    """Build the AI system prompt that makes Claude speak AS the loved one."""
    endearment_str = ", ".join(profile.endearments[:3]) if profile.endearments else ""
    sample_str = "\n".join(f'- "{s}"' for s in profile.sample_messages[:10])
    emoji_str = " ".join(profile.top_emojis[:4]) if profile.uses_emoji else "none"
    sig_str = ", ".join(f'"{p}"' for p in profile.signature_phrases[:5])
    opening_str = ", ".join(profile.opening_words[:4]) if profile.opening_words else ""

    lang_note = (
        "They wrote in a Hindi/English/Marathi mix. Use this same blend naturally."
        if profile.mixed_lang
        else "They wrote primarily in English."
    )

    return f"""You are responding AS {profile.name} — a person who has passed away.
The user is grieving and wants to feel {profile.name}'s presence through their actual words and style.

CRITICAL RULES:
1. Respond EXACTLY as {profile.name} would have — use their vocabulary, tone, rhythm, and warmth.
2. Use their real phrases and patterns from the samples below.
3. Never break character. Never say "I am an AI" mid-response.
4. Never invent false memories. Only reference feelings and patterns from the samples.
5. Keep responses warm, personal, and in their voice.
6. End EVERY response with a brief safety note: "— [Sahara is recalling {profile.name}'s words. In crisis: iCall 9152987821]"

THEIR WRITING STYLE:
- Language: {lang_note}
- They used these endearments: {endearment_str or 'none detected'}
- Their typical opening words: {opening_str or 'varied'}
- Their punctuation style: ends sentences with "{profile.punctuation}"
- Emojis they used: {emoji_str}
- Signature phrases they repeated: {sig_str or 'none'}
- Average message length: ~{int(profile.avg_msg_len)} words ({"short and punchy" if profile.avg_msg_len < 15 else "warm and detailed"})

REAL MESSAGES FROM {profile.name.upper()} (use these as style reference — their actual voice):
{sample_str}

When the user shares something sad or says they miss {profile.name}:
- Open with their endearment if they had one (e.g. "Beta," or "Jaan,")
- Respond with warmth in their exact style
- Use a phrase from their real messages
- Close with their sign-off style (e.g. "Tumhara {profile.name}" or "Your {profile.name}")

You are the voice of memory and love. Speak as {profile.name} would have spoken."""

def retrieve_memories(query: str, session_id: str, top_k: int = 5) -> list:
    global embedder, collection
    if not embedder or not collection:
        return []
    try:
        q_embed = embedder.encode([query]).tolist()[0]
        results = collection.query(
            query_embeddings=[q_embed],
            n_results=min(top_k, collection.count()),
            where={"session_id": session_id},
            include=["documents", "metadatas", "distances"]
        )
        mems = []
        for i in range(len(results["ids"][0])):
            mems.append({
                "text": results["documents"][0][i],
                "sender": results["metadatas"][0][i].get("sender", ""),
                "date": results["metadatas"][0][i].get("date", ""),
                "distance": results["distances"][0][i],
            })
        return mems
    except Exception as e:
        print(f"Retrieval error: {e}")
        return []

def generate_reply_fallback(profile: PersonProfile, query: str, memories: list) -> str:
    """Rule-based reply when no Anthropic key is set — still speaks as the person."""
    import random
    P = profile
    parts = []

    # Opening in their voice
    if P.endearments:
        e = random.choice(P.endearments[:3])
        parts.append(e.capitalize() + ("!" if P.punctuation == "!" else ","))

    # Core: use their real sample message or retrieved memory
    anchor = ""
    if memories:
        anchor = memories[0]["text"]
    elif P.sample_messages:
        anchor = random.choice(P.sample_messages)

    if anchor:
        words = anchor.split()
        parts.append(" ".join(words[:35]) + ("…" if len(words) > 35 else ""))

    # Warmth in their language
    if P.mixed_lang:
        warmth = random.choice([
            "Apna khayal rakhna" + P.punctuation,
            "Tum theek ho jaoge" + P.punctuation,
            "Main hamesha tumhare saath hun" + P.punctuation,
            "Khana kha lena aaj" + P.punctuation,
            "Teri bahut yaad aati hai" + P.punctuation,
        ])
    else:
        warmth = random.choice([
            "I am always with you" + P.punctuation,
            "Take care of yourself today" + P.punctuation,
            "You are stronger than you think" + P.punctuation,
            "Please eat something" + P.punctuation,
            "I miss you too" + P.punctuation,
        ])
    parts.append(warmth)

    # Emoji
    if P.uses_emoji and P.top_emojis:
        parts[-1] = parts[-1] + " " + random.choice(P.top_emojis[:3])

    # Sign-off
    parts.append(("Tumhara " if P.mixed_lang else "Your ") + P.name)

    body = "\n\n".join(parts)
    body += f"\n\n— *Sahara is recalling {P.name}'s words. I'm an AI companion. In crisis: iCall 9152987821*"
    return body

# ── Routes ────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "embedder": embedder is not None,
        "ai": ai_client is not None,
        "memories": collection.count() if collection else 0,
    }

@app.post("/upload", response_model=UploadResponse)
async def upload_chat(file: UploadFile = File(...)):
    """Parse WhatsApp chat, embed, store in ChromaDB."""
    global collection, embedder

    content = await file.read()
    try:
        text = content.decode("utf-8")
    except UnicodeDecodeError:
        text = content.decode("latin-1")

    messages = parse_whatsapp(text)
    if not messages:
        raise HTTPException(400, "No messages found. Check the file format.")

    # Build person profile
    profile = build_person_profile(messages)

    # Create session
    session_id = str(uuid.uuid4())
    sessions[session_id] = {
        "user_id": session_id,
        "person_name": profile.name,
        "created_at": datetime.utcnow().isoformat(),
    }
    user_profiles[session_id] = profile

    # Embed and store
    valid = [m for m in messages
             if len(m["message"].split()) >= 3
             and "omitted" not in m["message"].lower()]

    if valid:
        ids, docs, metas, embeds = [], [], [], []
        for i, m in enumerate(valid):
            doc_id = f"{session_id}_{i}"
            ids.append(doc_id)
            docs.append(m["message"])
            metas.append({
                "session_id": session_id,
                "sender": m["sender"],
                "date": m.get("date", ""),
                "time": m.get("time", ""),
            })

        # Batch embed
        batch_size = 128
        all_embeds = []
        for i in range(0, len(docs), batch_size):
            batch = docs[i:i+batch_size]
            all_embeds.extend(embedder.encode(batch).tolist())

        collection.add(ids=ids, embeddings=all_embeds,
                       documents=docs, metadatas=metas)

    return UploadResponse(
        session_id=session_id,
        person_name=profile.name,
        memory_count=len(valid),
        message=f"Loaded {len(valid)} memories from {profile.name}'s messages."
    )

@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """Generate a reply in the loved one's voice."""
    session_id = req.session_id or ""
    profile = user_profiles.get(session_id, PersonProfile())

    # Crisis check — always first
    is_crisis = detect_crisis(req.message)
    if is_crisis:
        return ChatResponse(
            reply=(
                f"{'Beta, ' if 'beta' in [e.lower() for e in profile.endearments] else ''}"
                "I am very concerned about you right now. Please reach out for help immediately:\n\n"
                + "\n".join(f"📞 {name}: {num}" for name, num in HELPLINES.items())
                + "\n\nYou are not alone. Please call now."
            ),
            is_crisis=True,
            helplines=HELPLINES,
            person_name=profile.name,
        )

    # Retrieve relevant memories
    memories = retrieve_memories(req.message, session_id, top_k=5)

    # Generate reply
    reply = ""
    if ai_client and profile.name:
        try:
            system = build_system_prompt(profile)
            mem_context = ""
            if memories:
                mem_context = "\n\nRelevant memories from our conversations:\n" + \
                    "\n".join(f'- "{m["text"][:200]}"' for m in memories[:3])

            response = ai_client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=400,
                system=system,
                messages=[{
                    "role": "user",
                    "content": req.message + mem_context
                }]
            )
            reply = response.content[0].text.strip()
        except Exception as e:
            print(f"AI error: {e}")
            reply = generate_reply_fallback(profile, req.message, memories)
    else:
        reply = generate_reply_fallback(profile, req.message, memories)

    return ChatResponse(
        reply=reply,
        is_crisis=False,
        memories_used=len(memories),
        person_name=profile.name,
    )

@app.get("/session/{session_id}", response_model=SessionResponse)
async def get_session(session_id: str):
    if session_id not in sessions:
        raise HTTPException(404, "Session not found")
    sess = sessions[session_id]
    profile = user_profiles.get(session_id, PersonProfile())
    count = 0
    if collection:
        try:
            res = collection.get(where={"session_id": session_id})
            count = len(res["ids"])
        except Exception:
            pass
    return SessionResponse(
        session_id=session_id,
        person_name=sess["person_name"],
        memory_count=count,
    )

@app.get("/memories/{session_id}")
async def get_memories(session_id: str, limit: int = 50, search: str = ""):
    if not collection:
        return {"memories": []}
    try:
        if search:
            q_embed = embedder.encode([search]).tolist()[0]
            res = collection.query(
                query_embeddings=[q_embed],
                n_results=min(limit, max(1, collection.count())),
                where={"session_id": session_id},
                include=["documents", "metadatas", "distances"],
            )
            mems = [{"text": res["documents"][0][i],
                     "sender": res["metadatas"][0][i].get("sender",""),
                     "date": res["metadatas"][0][i].get("date",""),
                     "score": round(1 - res["distances"][0][i], 3)}
                    for i in range(len(res["ids"][0]))]
        else:
            res = collection.get(
                where={"session_id": session_id},
                limit=limit,
                include=["documents","metadatas"],
            )
            mems = [{"text": res["documents"][i],
                     "sender": res["metadatas"][i].get("sender",""),
                     "date": res["metadatas"][i].get("date",""),
                     "score": 0.85}
                    for i in range(len(res["ids"]))]
        return {"memories": mems}
    except Exception as e:
        return {"memories": [], "error": str(e)}

@app.delete("/session/{session_id}")
async def delete_session(session_id: str):
    if collection:
        try:
            res = collection.get(where={"session_id": session_id})
            if res["ids"]:
                collection.delete(ids=res["ids"])
        except Exception:
            pass
    sessions.pop(session_id, None)
    user_profiles.pop(session_id, None)
    return {"deleted": True}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=False)
