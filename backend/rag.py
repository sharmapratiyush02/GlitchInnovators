"""
Sahara Phase 1 — Local RAG Pipeline (Minimal)
Run: python rag.py ingest _chat.txt
     python rag.py query "Missing Aai today"
"""
import re, sys, argparse
from sentence_transformers import SentenceTransformer
import chromadb

MODEL = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
DB    = chromadb.PersistentClient("./sahara_db")
COL   = DB.get_or_create_collection("memories", metadata={"hnsw:space": "cosine"})

# ── 1. Parse WhatsApp export ──────────────────────────────────────────────────
def parse(path):
    pattern = re.compile(r"^(\d{1,2}/\d{1,2}/\d{2,4}),?\s+\d{1,2}:\d{2}.*?-\s+([^:]+):\s+(.+)$")
    msgs = []
    for line in open(path, encoding="utf-8", errors="replace"):
        m = pattern.match(line.strip())
        if m and "<" not in m.group(3):   # skip system messages
            msgs.append({"date": m.group(1), "sender": m.group(2).strip(), "text": m.group(3).strip()})
    return msgs

# ── 2. Chunk + embed + store ──────────────────────────────────────────────────
def ingest(path):
    msgs   = parse(path)
    chunks = [msgs[i:i+5] for i in range(0, len(msgs), 3)]   # size-5, stride-3

    texts, ids, metas = [], [], []
    for i, chunk in enumerate(chunks):
        cid = f"c{i}"
        if cid in (COL.get()["ids"] or []): continue
        texts.append("\n".join(f"[{m['date']}] {m['sender']}: {m['text']}" for m in chunk))
        ids.append(cid)
        metas.append({"date": chunk[0]["date"], "senders": ", ".join({m["sender"] for m in chunk})})

    if texts:
        embs = MODEL.encode(texts, normalize_embeddings=True).tolist()
        COL.add(ids=ids, embeddings=embs, documents=texts, metadatas=metas)
    print(f"✅ Ingested {len(msgs)} messages → {len(texts)} new chunks (total: {COL.count()})")

# ── 3. Semantic retrieval ─────────────────────────────────────────────────────
def query(q, k=5):
    emb  = MODEL.encode([q], normalize_embeddings=True).tolist()
    res  = COL.query(query_embeddings=emb, n_results=min(k, COL.count()),
                     include=["documents", "metadatas", "distances"])
    memories = []
    for doc, meta, dist in zip(res["documents"][0], res["metadatas"][0], res["distances"][0]):
        memories.append({"text": doc, "date": meta["date"],
                         "senders": meta["senders"], "score": round(1 - dist, 3)})
        print(f"\n🌿 [{meta['date']}] {meta['senders']}  (score: {round(1-dist,3)})")
        print(doc[:300])
    return memories

# ── CLI ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd",  choices=["ingest", "query", "clear"])
    ap.add_argument("arg",  nargs="?", help="chat file or query string")
    args = ap.parse_args()

    if   args.cmd == "ingest": ingest(args.arg)
    elif args.cmd == "query":  query(args.arg)
    elif args.cmd == "clear":  DB.delete_collection("memories"); print("🗑️  Cleared")