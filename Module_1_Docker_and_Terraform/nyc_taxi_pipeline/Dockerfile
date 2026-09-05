FROM python:3.11-slim

RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Module_1_Docker_and_Terraform/nyc_taxi_pipeline/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY scripts/ingest_data.py .

ENTRYPOINT ["python", "ingest_data.py"]

