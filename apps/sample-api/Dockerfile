FROM python:3.12-slim

WORKDIR /app

# Abhängigkeiten zuerst => Layer-Caching bei unveränderten requirements.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

EXPOSE 8000

# Non-root User (Security-Best-Practice; Kyverno erzwingt es zusätzlich im Cluster).
RUN useradd -u 10001 appuser
USER 10001

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
