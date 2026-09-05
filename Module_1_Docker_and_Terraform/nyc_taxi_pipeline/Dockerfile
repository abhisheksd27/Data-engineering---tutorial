FROM python:3.11-slim

# Install system utilities
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the ingestion script
COPY scripts/ingest_data.py .

ENTRYPOINT ["python", "ingest_data.py"]