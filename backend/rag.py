import re
import os
from datetime import datetime
from sentence_transformers import SentenceTransformer
import chromadb
from chromadb.config import Settings
import numpy as np  # For potential cosine similarity if needed

# Initialize the embedding model (use a lightweight model suitable for on-device)
embedder = SentenceTransformer('all-MiniLM-L6-v2')  # Or a quantized version for mobile

# Function to parse WhatsApp chat export (_chat.txt)
def parse_whatsapp_chat(file_path):
    """
    Parses a WhatsApp chat export file and normalizes the data into a list of dictionaries.
    Each dict contains: 'date' (datetime), 'sender' (str), 'message' (str)
    Supports common formats like [dd/mm/yyyy, h:mm:ss AM/PM] Sender: message
    """
    messages = []
    # Updated pattern for [dd/mm/yyyy, h:mm:ss AM/PM] Sender: message (non-capturing for AM/PM)
    date_pattern = r'\[(\d{1,2}/\d{1,2}/\d{4}), (\d{1,2}:\d{2}:\d{2} (?:AM|PM))\] (.*?): (.*)'
    # Fallback for other formats: (mm/dd/yy, h:mm AM/PM) - Sender: message
    fallback_pattern = r'(\d{1,2}/\d{1,2}/\d{2}), (\d{1,2}:\d{2}) (?:AM|PM) - (.*?): (.*)'

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        current_message = None
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Try primary pattern
            match = re.match(date_pattern, line)
            if not match:
                # Try fallback
                match = re.match(fallback_pattern, line)

            if match:
                if current_message:
                    # Append to previous if multi-line
                    current_message['message'] += ' ' + line
                else:
                    # New message
                    groups = match.groups()
                    if len(groups) == 4:
                        date_str, time_str, sender, message = groups
                        full_date_str = f"{date_str} {time_str}"
                        # Try parse with common formats
                        date_formats = [
                            '%d/%m/%Y %I:%M:%S %p',  # dd/mm/yyyy
                            '%m/%d/%y %I:%M %p',     # mm/dd/yy
                            '%d/%m/%y %H:%M'         # 24h fallback
                        ]
                        date_obj = None
                        for fmt in date_formats:
                            try:
                                date_obj = datetime.strptime(full_date_str, fmt)
                                break
                            except ValueError:
                                continue
                        if date_obj:
                            current_message = {
                                'date': date_obj,
                                'sender': sender.strip(),
                                'message': message.strip()
                            }
                            messages.append(current_message)
                    else:
                        continue
            elif current_message:
                # Multi-line continuation
                current_message['message'] += ' ' + line

    print(f"Parsed {len(messages)} messages.")
    return messages

# Function to create vector store with embeddings
def create_vector_store(messages, collection_name='sahara_memories'):
    """
    Generates embeddings for each message chunk and stores them in a local ChromaDB collection.
    """
    client = chromadb.PersistentClient(path="./chroma_db")  # Local persistent storage

    # Check if collection exists, delete if it does (for fresh start in hackathon)
    try:
        existing = client.get_collection(collection_name)
        client.delete_collection(collection_name)
    except:
        pass

    collection = client.create_collection(
        name=collection_name
    )

    # Prepare data
    ids = []
    documents = []
    metadatas = []
    for i, msg in enumerate(messages):
        chunk = msg['message']
        if chunk and len(chunk) > 10:  # Skip very short/empty
            ids.append(str(i))
            documents.append(chunk)
            metadatas.append({
                'date': msg['date'].isoformat(),
                'sender': msg['sender']
            })

    if ids:
        # Batch embed
        embeddings = embedder.encode(documents).tolist()
        collection.add(
            ids=ids,
            embeddings=embeddings,
            metadatas=metadatas,
            documents=documents
        )
        print(f"Added {len(ids)} embeddings to collection '{collection_name}'.")
    else:
        print("No messages to embed.")

    return collection

# Function for retrieval
def retrieve_memories(query, collection_name='sahara_memories', top_k=5):
    """
    Embeds the query and performs cosine similarity search in ChromaDB to retrieve top_k relevant memories.
    Returns list of dicts: {'document': str, 'metadata': dict, 'distance': float}
    """
    client = chromadb.PersistentClient(path="./chroma_db")
    collection = client.get_collection(name=collection_name)

    # Embed query
    query_embedding = embedder.encode([query]).tolist()[0]

    # Query
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        include=['documents', 'metadatas', 'distances']
    )

    retrieved = []
    for i in range(len(results['ids'][0])):
        retrieved.append({
            'document': results['documents'][0][i],
            'metadata': results['metadatas'][0][i],
            'distance': results['distances'][0][i]
        })

    return retrieved
def generate_response(user_message):
    memories = retrieve_memories(user_message)

    if not memories:
        return "Main sun raha/rahi hoon... Thoda aur bataoge?"

    formatted = []
    for mem in memories:
        formatted.append(
            f"[{mem['metadata']['date'][:10]}] {mem['metadata']['sender']}: {mem['document']}"
        )

    context = "\n\n".join(formatted)

    return f"🌿 Mujhe yaad hai:\n\n{context}\n\nTum aur batana chahoge?"

# Example usage (for testing/demo)
if __name__ == "__main__":
    # Replace with your file path (from Flutter file picker)
    file_path = "backend/sample_chat.txt"  # e.g., sample_chat.txt

    # Step 1: Parse
    messages = parse_whatsapp_chat(file_path)
    print("\nSample Parsed Messages:")
    for msg in messages[:2]:  # Show first 2
        print(f"{msg['date']} - {msg['sender']}: {msg['message'][:50]}...")

    # Step 2: Create vector store
    collection = create_vector_store(messages)

    # Step 3: Retrieve example (grief prompt)
    query = "Missing Aai today"  # Example in Marathi/English mix if needed
    memories = retrieve_memories(query)
    print("\nRetrieved Memories (based on sample chat):")
    for mem in memories:
        print(f"Distance: {mem['distance']:.4f} | Sender: {mem['metadata']['sender']} | Date: {mem['metadata']['date'][:10]} | Message: {mem['document']}")