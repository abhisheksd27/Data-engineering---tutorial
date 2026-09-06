# NYC Taxi Pipeline — Module 2 (Kestra Orchestration)

## Overview

This project automates the Module 1 NYC Taxi data pipeline using **Kestra** as the orchestration engine.  
Instead of running Python scripts manually, Kestra flows handle download → S3 upload → PostgreSQL ingestion on a schedule.

---

## Architecture

```
[Kestra (Docker port 8080)]
        │
        ├── Flow 01: Hello World
        ├── Flow 02: Python task demo
        ├── Flow 03: Taxi → PostgreSQL (one-time)
        ├── Flow 04: Taxi → PostgreSQL (scheduled, parameterized)
        ├── Flow 05: Taxi → S3
        └── Flow 06: Full pipeline (S3 + PostgreSQL + monthly schedule)
                            │
                  ┌─────────┴──────────┐
                  ▼                    ▼
            PostgreSQL              AWS S3
            ny_taxi DB        ny-taxi-data-lake-*/raw/
                                        │
                                   AWS Athena
                                  ny_taxi_db
```

---

## Prerequisites

- Docker Desktop running
- AWS account with `abhishekshankar` IAM user (from Module 1)
- S3 bucket `ny-taxi-data-lake-abhishekshankar-826674` (from Module 1 Terraform)
- Conda env `de-zoomcamp` (for running scripts standalone)

---

## Quick Start

### 1. Configure `.env`

Open `.env` and fill in your AWS credentials:

```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

### 2. Start all services

```bash
docker compose up -d
```

### 3. Open Kestra UI

http://localhost:8080

### 4. Add AWS credentials to Kestra KV Store

Kestra UI → **KV Store** → Add:
- Key: `AWS_ACCESS_KEY_ID`  → your IAM access key
- Key: `AWS_SECRET_ACCESS_KEY` → your IAM secret

### 5. Import all flows

```bash
for f in flows/*.yaml; do
  curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@$f
done
```

### 6. Run Flow 01 first (Hello World test)

Kestra UI → Flows → `hello_world` → Execute

---

## Flows Summary

| Flow File | ID | What It Does |
|---|---|---|
| `01_hello_world.yaml` | `hello_world` | Basic Kestra concepts |
| `02_python_task.yaml` | `python_task_demo` | Run Python inside Kestra |
| `03_postgres_taxi.yaml` | `postgres_taxi_etl` | Download + load to PostgreSQL |
| `04_postgres_taxi_scheduled.yaml` | `postgres_taxi_scheduled` | Monthly schedule + any color/month |
| `05_aws_s3_taxi.yaml` | `aws_s3_taxi_upload` | Download + upload to S3 |
| `06_aws_s3_taxi_scheduled.yaml` | `full_taxi_pipeline_scheduled` | Complete pipeline, monthly schedule |

---

## Validating Results

### PostgreSQL

```bash
docker exec -it nyc_taxi_pipeline_m2-postgres-taxi-1 psql -U root -d ny_taxi
```

```sql
SELECT COUNT(*) FROM green_taxi_trips;
SELECT year, month, COUNT(*) FROM green_taxi_trips GROUP BY year, month ORDER BY year, month;
```

### S3

```bash
aws s3 ls s3://ny-taxi-data-lake-abhishekshankar-826674/raw/ --region us-east-1
```

### Athena

Run queries from `queries/athena_queries.sql` in AWS Athena Console.  
Workgroup: `ny_taxi_workgroup` | Database: `ny_taxi_db`

---

## Stopping Services

```bash
docker compose down        # stop (keep data)
docker compose down -v     # stop + delete all volumes
```

---

## Troubleshooting

| Error | Fix |
|---|---|
| `localhost:8080` not loading | Wait 30s after `docker compose up -d` |
| Port 8080 already in use | `docker stop pgadmin` (from Module 1) |
| `ModuleNotFoundError` in Python task | Add `pip install <pkg>` in `beforeCommands` |
| S3 upload fails (403) | Check AWS credentials in Kestra KV Store |
| `postgres-taxi` connection refused | Ensure service is healthy: `docker compose ps` |
| Kestra shows `FAILED` execution | Click execution → task → Logs for full error |
