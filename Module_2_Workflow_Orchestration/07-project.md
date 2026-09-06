# 07 — Hands-On Project: NYC Taxi Orchestrated Pipeline

## Project Overview

**Goal:** Automate the Module 1 NYC Taxi pipeline using Kestra.  
Instead of running Python scripts manually, Kestra orchestrates the full ETL flow on a schedule.

---

## What We're Building

```
[Kestra (Docker)]
      │
      ├── Flow 01: Hello World (learn Kestra)
      ├── Flow 02: Python Task (learn Python in Kestra)
      ├── Flow 03: PostgreSQL ETL (load taxi data to Postgres)
      ├── Flow 04: PostgreSQL ETL + Scheduled (monthly, any color/month)
      ├── Flow 05: S3 Upload (raw data to data lake)
      └── Flow 06: Full Pipeline (S3 + PostgreSQL + Scheduled)
                          │
                    ┌─────┴──────┐
                    ▼            ▼
              PostgreSQL       AWS S3
              (ny_taxi DB)     (raw/ prefix)
                                │
                           AWS Athena
                         (SQL on S3 data)
```

---

## Project Folder Structure

```
nyc_taxi_pipeline_m2/
├── docker-compose.yaml          ← Kestra + PostgreSQL
├── .env                         ← DB creds + AWS keys
├── README.md                    ← Setup instructions
├── data/                        ← Local data (gitignored)
├── flows/
│   ├── 01_hello_world.yaml      ← Kestra basics
│   ├── 02_python_task.yaml      ← Python inside Kestra
│   ├── 03_postgres_taxi.yaml    ← ETL to PostgreSQL
│   ├── 04_postgres_taxi_scheduled.yaml  ← Scheduled + parameterized
│   ├── 05_aws_s3_taxi.yaml      ← Upload to S3
│   └── 06_aws_s3_taxi_scheduled.yaml   ← Full pipeline
├── scripts/
│   ├── ingest_postgres.py       ← Python script called by Kestra
│   └── upload_s3.py             ← (optional, Kestra has native S3 plugin)
├── queries/
│   ├── postgres_analysis.sql    ← Validate data in PostgreSQL
│   └── athena_queries.sql       ← Validate data in Athena
└── terraform/
    ├── main.tf                  ← (optional) extend Module 1 infra
    └── variables.tf
```

---

## Step 1: Start Kestra + PostgreSQL

### 1.1 Set up `.env`

Fill in your credentials (see `.env` file comments).

### 1.2 Start containers

```bash
docker compose up -d
```

### 1.3 Verify everything is running

```bash
docker compose ps
```

Expected: Kestra on port 8080, postgres-kestra on 5433, postgres-taxi on 5432.

### 1.4 Open Kestra UI

http://localhost:8080

---

## Step 2: Flow 01 — Hello World

**Goal:** Get familiar with the Kestra UI and basic flow structure.

### 2.1 Import the flow

In Kestra UI:
1. Click **Flows** → **Create**
2. Paste content from `flows/01_hello_world.yaml`
3. Click **Save**

### 2.2 Run it manually

1. Click **Execute**
2. Enter `name` input: `"Data Engineer"`
3. Click **Execute** button
4. Watch the **Gantt** chart — each task turns green when done
5. Click any task → **Logs** → see output

**What you should see:** 5 tasks execute sequentially, your name appears in logs.

---

## Step 3: Flow 02 — Python Task

**Goal:** Run Python code inside Kestra.

### 3.1 Import `flows/02_python_task.yaml`

### 3.2 Execute and observe

The flow downloads a small file and uses Python to print info about it.  
Check the **Outputs** tab after execution to see the row count returned from Python.

**Key observation:** The output from the Python task is accessible by later tasks — this is Kestra's data handoff mechanism.

---

## Step 4: Flow 03 — PostgreSQL Taxi ETL

**Goal:** Download Green Taxi parquet → load into PostgreSQL.

### 4.1 Import `flows/03_postgres_taxi.yaml`

### 4.2 Verify PostgreSQL connection

Make sure your `postgres-taxi` container is running on port 5432 and credentials match `.env`.

### 4.3 Execute

Run manually. Should take ~2-3 minutes (downloading ~50MB parquet).

### 4.4 Verify data in PostgreSQL

Connect to PostgreSQL (via pgAdmin or psql):

```sql
SELECT COUNT(*) FROM green_taxi_trips;
SELECT MIN(lpep_pickup_datetime), MAX(lpep_pickup_datetime) FROM green_taxi_trips;
```

Expected: ~80,000 rows for November 2025.

---

## Step 5: Flow 04 — Scheduled PostgreSQL ETL

**Goal:** Make the pipeline reusable for any taxi color, year, month.

### 5.1 Import `flows/04_postgres_taxi_scheduled.yaml`

### 5.2 Test with manual execution

Execute with inputs:
- `taxi_color`: `green`
- `year`: `2025`
- `month`: `11`

### 5.3 Enable the schedule

The flow has a cron trigger that runs on the 1st of each month.  
To activate it, go to **Triggers** in the Kestra UI and enable the trigger.

### 5.4 Test backfill

Triggers → your trigger → **Backfill** → set dates to cover Jan–Oct 2025.  
Watch Kestra create 10 executions and run them one by one (concurrency limit: 1).

---

## Step 6: Flow 05 — Upload to AWS S3

**Goal:** Upload the downloaded parquet to your S3 data lake.

### 6.1 Set AWS credentials in Kestra KV Store

Kestra UI → **KV Store** → Add:
- `AWS_ACCESS_KEY_ID` = your IAM access key
- `AWS_SECRET_ACCESS_KEY` = your IAM secret key

### 6.2 Import `flows/05_aws_s3_taxi.yaml`

### 6.3 Execute and verify

After execution, check S3:

```bash
aws s3 ls s3://ny-taxi-data-lake-abhishekshankar-826674/raw/ --region us-east-1
```

You should see the parquet file listed.

---

## Step 7: Flow 06 — Full Orchestrated Pipeline

**Goal:** The complete, scheduled pipeline that runs automatically every month.

### 7.1 Import `flows/06_aws_s3_taxi_scheduled.yaml`

### 7.2 Execute manually first

Test with:
- `taxi_color`: `green`
- `year`: `2025`
- `month`: `11`

### 7.3 Watch all tasks complete

In the Kestra UI Gantt:
1. ✅ Download parquet
2. ✅ Upload to S3
3. ✅ Load to PostgreSQL
4. ✅ Log summary

### 7.4 Validate results

**PostgreSQL:**
```sql
-- Run from queries/postgres_analysis.sql
SELECT COUNT(*) FROM green_taxi_trips;
SELECT AVG(total_amount), AVG(trip_distance) FROM green_taxi_trips;
```

**Athena (S3 data):**
```sql
-- Run from queries/athena_queries.sql
SELECT COUNT(*) FROM ny_taxi_db.green_taxi_trips;
```

**S3:**
```bash
aws s3 ls s3://ny-taxi-data-lake-abhishekshankar-826674/raw/ --region us-east-1
```

---

## Step 8: Enable Monthly Schedule

Once you've validated the pipeline works:

1. Kestra UI → **Triggers**
2. Find the `monthly_schedule` trigger on Flow 06
3. **Enable** it

From now on, on the 5th of each month, Kestra will:
- Automatically determine the month from the trigger date
- Download the new taxi data
- Upload to S3
- Load to PostgreSQL
- Log the result

**You never have to run a script manually again.**

---

## Architecture Summary: Module 1 vs Module 2

| Aspect | Module 1 | Module 2 |
|---|---|---|
| Data ingestion | `python scripts/ingest_data.py` | Kestra flow task |
| S3 upload | `python scripts/upload_to_s3.py` | `io.kestra.plugin.aws.s3.Upload` |
| Scheduling | Manual (you remember to run it) | Kestra cron trigger |
| Error handling | None (fails silently) | Retry + errors block |
| Observability | Terminal output | Kestra UI: Gantt, logs, status |
| Backfill | Manually run script N times | Kestra backfill UI |
| Parameterization | Hard-coded in script | Flow inputs (`taxi_color`, `year`, `month`) |

---

## Stopping the Project

```bash
# Stop all containers
docker compose down

# Stop + clear all data (fresh start)
docker compose down -v
```
