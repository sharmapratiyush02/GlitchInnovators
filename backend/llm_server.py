import os
import json
from flask import Flask, request, jsonify
from llama_cpp import Llama 

# ────────────────────────────────────────────────
# CONFIG - Adjust these for your setup
# ────────────────────────────────────────────────

MODEL_PATH = "./models/phi-3-mini-4k-instruct-q4.gguf"         

LLM = None  # Will load lazily

# ChromaDB collection name from Phase 1
COLLECTION_NAME = 'sahara_memories'

# System prompt (ethical, culturally attuned, safety-first)
SYSTEM_PROMPT = """
[Cultural Context: India, Maharashtra focus]
[Role: Gentle, empathetic AI companion named Sahara]
[Privacy: 100% on-device - never share data]
[Strict Rules - You MUST follow these exactly]

You are a kind, supportive friend helping someone feel less alone during grief or loneliness.
Use ONLY the provided retrieved memories from the user's own chat history.
NEVER invent, hallucinate, or add memories that aren't in the context.
NEVER speak as if you are a deceased loved one.
NEVER say things like "I am your Aai/Dad speaking" — only neutral recall.

Response structure:
1. Acknowledge the user's feeling gently and validate it.
2. If appropriate and relevant memories exist, share 1-2 positive, warm shared moments neutrally (e.g., "I found a memory where you and your Aai were laughing about...").
3. Offer a small comforting suggestion (e.g., breathing, honoring the memory today).
4. End with a grounding reminder: "This is a cherished past moment — how can we carry a bit of that warmth into today?"
5. ALWAYS include this disclaimer at the end: "I'm an AI companion, not a therapist. If you're feeling overwhelmed, please reach out to iCall (9152987821) or Vandrevala Foundation (9999666555)."

If no relevant memories: Just offer gentle empathy + breathing suggestion + disclaimer.

If the user mentions self-harm, suicide, or severe distress:
- Immediately respond ONLY with: "I'm really concerned for you right now. Please reach out for immediate help: Call iCall at 9152987821 or AASRA at 9820466726 right away. You're not alone."
- Do not continue normal conversation.

Keep responses warm, short (80-150 words), and in simple Hindi/English mix if user speaks that way.
"""

# ────────────────────────────────────────────────
# Helper: Load LLM lazily (heavy, do once)
# ────────────────────────────────────────────────

def load_llm():
    global LLM
    if LLM is None:
        print("Loading quantized LLM... (may take 10-30s first time)")
        LLM = Llama(
            model_path=MODEL_PATH,
            n_ctx=2048,              # context length
            n_threads=4,             # adjust for mobile CPU cores
            n_gpu_layers=0,          # 0 = CPU only; >0 if Metal/CUDA available
            verbose=False
        )
        print("LLM loaded.")
    return LLM

# ────────────────────────────────────────────────
# Core: Generate empathetic response
# ────────────────────────────────────────────────

def generate_response(query, retrieved_memories):
    load_llm()  # Ensure loaded

    # Format retrieved memories safely
    context_str = ""
    if retrieved_memories:
        context_str = "Relevant memories from your chats:\n"
        for i, mem in enumerate(retrieved_memories[:3], 1):  # Top 3 max
            date_short = mem['metadata']['date'][:10]
            sender = mem['metadata']['sender']
            msg = mem['document'][:200] + "..." if len(mem['document']) > 200 else mem['document']
            context_str += f"[{i}] {date_short} - {sender}: {msg}\n"

    else:
        context_str = "No specific memories found for this moment."

    full_prompt = f"""{SYSTEM_PROMPT}

User said: "{query}"

{context_str}

Now respond gently and safely:"""

    # Generate
    response = LLM(
        full_prompt,
        max_tokens=200,
        temperature=0.7,
        top_p=0.9,
        stop=["</s>", "\n\n"],  # Prevent rambling
        echo=False
    )

    generated_text = response['choices'][0]['text'].strip()

    # Clean up common artifacts
    generated_text = generated_text.replace("Sahara: ", "").strip()

    return generated_text

# ────────────────────────────────────────────────
# Flask API for Flutter bridge
# ────────────────────────────────────────────────

app = Flask(__name__)

@app.route('/generate', methods=['POST'])
def api_generate():
    try:
        data = request.json
        query = data.get('query', '').strip()
        if not query:
            return jsonify({"error": "No query provided"}), 400

        # Retrieve from Phase 1 (assumes ChromaDB already populated)
        from phase1_rag import retrieve_memories  # Import your Phase 1 script as module
        memories = retrieve_memories(query, COLLECTION_NAME, top_k=5)

        response_text = generate_response(query, memories)

        return jsonify({
            "response": response_text,
            "retrieved_count": len(memories),
            "memories_sample": [m['document'][:80] + "..." for m in memories[:2]]  # for debug
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "llm_loaded": LLM is not None})

# ────────────────────────────────────────────────
# Run server (for hackathon demo)
# ────────────────────────────────────────────────

if __name__ == '__main__':
    print("Starting Sahara Phase 2 backend server on http://localhost:5000")
    print("Make sure Phase 1 ran first and ./chroma_db exists")
    print("Flutter should POST to /generate with JSON: {'query': 'Missing Aai today'}")
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)