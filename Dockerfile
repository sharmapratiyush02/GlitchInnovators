# ── Stage 1: Build React frontend ──────────────────────────────
FROM node:20-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package.json .
RUN npm install
COPY frontend/ .
ENV VITE_API_URL=/api
RUN npm run build

# ── Stage 2: Python backend + nginx to serve frontend ──────────
FROM python:3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc g++ curl nginx \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download embedding model so first request is instant
RUN python -c "from sentence_transformers import SentenceTransformer; \
    SentenceTransformer('all-MiniLM-L6-v2')"

# Backend code
COPY backend/ ./backend/

# Built React app from stage 1
COPY --from=frontend-builder /app/frontend/dist ./frontend-dist/

# Nginx: serve React on port 7860, proxy /api/* → FastAPI on 8000
RUN printf 'server {\n\
    listen 7860;\n\
    root /app/frontend-dist;\n\
    index index.html;\n\
    location /api/ {\n\
        proxy_pass http://127.0.0.1:8000/;\n\
        proxy_set_header Host $host;\n\
        proxy_read_timeout 60s;\n\
        client_max_body_size 50M;\n\
    }\n\
    location / { try_files $uri $uri/ /index.html; }\n\
}\n' > /etc/nginx/conf.d/default.conf && \
    rm -f /etc/nginx/sites-enabled/default

# Startup: nginx in background + uvicorn in foreground
RUN printf '#!/bin/bash\nnginx\ncd /app/backend\nuvicorn main:app --host 127.0.0.1 --port 8000\n' \
    > /start.sh && chmod +x /start.sh

# HF Spaces requires port 7860
EXPOSE 7860

CMD ["/start.sh"]
