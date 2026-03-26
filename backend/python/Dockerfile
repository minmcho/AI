# ── Build stage ───────────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# Pre-download NLLB-200 model so the first request is instant
# HF_HOME is set so the cache lands inside /install for the COPY below
ENV HF_HOME=/install/huggingface
RUN python - <<'EOF'
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
AutoTokenizer.from_pretrained("facebook/nllb-200-distilled-600M")
AutoModelForSeq2SeqLM.from_pretrained("facebook/nllb-200-distilled-600M")
print("NLLB-200 model cached successfully")
EOF

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime
WORKDIR /app
COPY --from=builder /install /usr/local
ENV HF_HOME=/usr/local/huggingface
COPY . .

# Non-root user
RUN adduser --disabled-password --gecos "" appuser
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4", "--proxy-headers"]
