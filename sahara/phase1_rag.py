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
    messages = []
    date_pattern = r'\[(\d{1,2}/\d{1,2}/\d{4}), (\d{1,2}:\d{2}:\d{2} (?:AM|PM))\] (.*?): (.*)'
    fallback_pattern = r'(\d{1,2}/\d{1,2}/\d{2}), (\d{1,2}:\d{2}) (?:AM|PM) - (.*?): (.*)'

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        current_message = None
        for line in f:
            line = line.strip()
            if not line:
                continue

            match = re.match(date_pattern, line)
            if not match:
                match = re.match(fallback_pattern, line)

            if match:
                if current_message:
                    current_message['message'] += ' ' + line
                else:
                    groups = match.groups()
                    if len(groups) == 4:
                        date_str, time_str, sender, message = groups
                        full_date_str = f"{date_str} {time_str}"
                        date_formats = [
                            '%d/%m/%Y %I:%M:%S %p',
                            '%m/%d/%y %I:%M %p',
                            '%d/%m/%y %H:%M'
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
                current_message['message'] += ' ' + line

    print(f"Parsed {len(messages)} messages.")
    return messages

def create_vector_store(messages, collection_name='sahara_memories'):
    client = chromadb.PersistentClient(path="./chroma_db")

    try:
        existing = client.get_collection(collection_name)
        client.delete_collection(collection_name)
    except:
        pass

    collection = client.create_collection(name=collection_name)

    ids = []
    documents = []
    metadatas = []
    for i, msg in enumerate(messages):
        chunk = msg['message']
        if chunk and len(chunk) > 10:
            ids.append(str(i))
            documents.append(chunk)
            metadatas.append({
                'date': msg['date'].isoformat(),
                'sender': msg['sender']
            })

    if ids:
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

def retrieve_memories(query, collection_name='sahara_memories', top_k=5):
    client = chromadb.PersistentClient(path="./chroma_db")
    collection = client.get_collection(name=collection_name)

    query_embedding = embedder.encode([query]).tolist()[0]

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

if __name__ == "__main__":
    file_path = "path/to/_chat.txt"

    messages = parse_whatsapp_chat(file_path)
    print("\nSample Parsed Messages:")
    for msg in messages[:2]:
        print(f"{msg['date']} - {msg['sender']}: {msg['message'][:50]}...")

    collection = create_vector_store(messages)

    query = "Missing Aai today"
    memories = retrieve_memories(query)
    print("\nRetrieved Memories (based on sample chat):")
    for mem in memories:
        print(f"Distance: {mem['distance']:.4f} | Sender: {mem['metadata']['sender']} | Date: {mem['metadata']['date'][:10]} | Message: {mem['document']}")
