# 04 — Building ETL Pipelines with Kestra

## What We're Building

A series of progressively more complex Kestra flows:

```
Flow 01: Hello World (learn flow structure)
    ↓
Flow 02: Run Python inside Kestra
    ↓
Flow 03: NYC Taxi → PostgreSQL (one-time run)
    ↓
Flow 04: NYC Taxi → PostgreSQL (scheduled + parameterized)
    ↓
Flow 05: NYC Taxi → S3 (upload to data lake)
    ↓
Flow 06: NYC Taxi → S3 (scheduled, parameterized, full pipeline)
```

---

## Flow 01: Hello World

**Purpose:** Understand the basic flow structure — tasks, inputs, outputs, variables, triggers.

**File:** `flows/01_hello_world.yaml`

**What it does:**
- Takes a name as input
- Greets the user using a variable
- Returns a message as output
- Logs the output
- Schedules itself to run daily

**Key concepts demonstrated:** `inputs`, `variables`, `outputs`, `triggers`, `pluginDefaults`, `concurrency`

**How to run:**
1. Import into Kestra UI
2. Click Execute
3. Enter your name as input
4. Watch task logs in real time

---

## Flow 02: Run Python Inside Kestra

**Purpose:** Learn how to execute Python scripts within a Kestra flow.

**File:** `flows/02_python_task.yaml`

**What it does:**
- Downloads Green Taxi data (parquet) from NYC TLC
- Passes the file as input to a Python script
- Python script reads the parquet with pandas, prints shape
- Returns row count as output to Kestra

**Two ways to run Python in Kestra:**

### Inline Script
```yaml
- id: process_data
  type: io.kestra.plugin.scripts.python.Script
  script: |
    import pandas as pd
    df = pd.read_parquet("data.parquet")
    print(f"Rows: {len(df)}")
```

### External Script File
```yaml
- id: process_data
  type: io.kestra.plugin.scripts.python.Commands
  inputFiles:
    ingest.py: "{{ read('scripts/ingest_postgres.py') }}"
  commands:
    - python ingest.py
```

**Install packages in Kestra Python tasks:**
```yaml
- id: process_data
  type: io.kestra.plugin.scripts.python.Script
  beforeCommands:
    - pip install pandas pyarrow boto3 sqlalchemy psycopg2-binary -q
  script: |
    import pandas as pd
    ...
```

---

## Flow 03: NYC Taxi → PostgreSQL (One-time)

**Purpose:** Build a real ETL pipeline: Download parquet → Load into PostgreSQL.

**File:** `flows/03_postgres_taxi.yaml`

**Architecture:**
```
[HTTP Download Task]
    → parquet file in Kestra internal storage
        ↓
[Python Script Task]
    → reads parquet with pandas
    → connects to PostgreSQL
    → inserts data in chunks
        ↓
[Log Task]
    → print total rows inserted
```

**Steps in the flow:**

**Step 1: Download the file**
```
Task type: io.kestra.plugin.core.http.Download
URI: https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
```

**Step 2: Run Python ingestion**
```
Task type: io.kestra.plugin.scripts.python.Script
- beforeCommands: pip install pandas pyarrow sqlalchemy psycopg2-binary
- inputFiles: data.parquet = {{ outputs.download.uri }}
- script: read parquet → write to PostgreSQL via SQLAlchemy
```

**Step 3: Log success**
```
Task type: io.kestra.plugin.core.log.Log
- message: Inserted {{ outputs.python_task.vars.row_count }} rows
```

---

## Flow 04: PostgreSQL Pipeline — Scheduled & Parameterized

**Purpose:** Make the pipeline reusable for any taxi color / month / year.

**File:** `flows/04_postgres_taxi_scheduled.yaml`

**Key additions over Flow 03:**
- `inputs`: `taxi_color`, `year`, `month`
- Dynamic URL built from inputs: `https://d37ci6vzurychx.cloudfront.net/trip-data/{{ inputs.taxi_color }}_tripdata_{{ inputs.year }}-{{ '%02d' | format(inputs.month) }}.parquet`
- Dynamic table name: `{{ inputs.taxi_color }}_taxi_trips_{{ inputs.year }}_{{ inputs.month }}`
- Cron trigger: runs on 1st of each month
- `concurrency: limit: 1` — prevents parallel runs from overlapping

**Backfill:**  
Kestra supports backfilling — you can replay the trigger for past months.  
In Kestra UI: Triggers → your trigger → "Backfill" → set start/end date range.

---

## Flow 05: NYC Taxi → AWS S3

**Purpose:** Upload the downloaded taxi parquet to your S3 data lake.

**File:** `flows/05_aws_s3_taxi.yaml`

**Architecture:**
```
[HTTP Download Task]
    → parquet in Kestra storage
        ↓
[AWS S3 Upload Task]
    → uploads to s3://ny-taxi-data-lake-abhishekshankar-826674/raw/
```

**AWS S3 Plugin:**
```
Task type: io.kestra.plugin.aws.s3.Upload
- bucket: ny-taxi-data-lake-abhishekshankar-826674
- key: raw/green_tripdata_2025-11.parquet
- from: {{ outputs.download.uri }}
- region: us-east-1
- accessKeyId: {{ secret('AWS_ACCESS_KEY_ID') }}
- secretKeyId: {{ secret('AWS_SECRET_ACCESS_KEY') }}
```

**Setting AWS Secrets in Kestra:**  
Go to Kestra UI → KV Store → Add Key:
- Key: `AWS_ACCESS_KEY_ID`, Value: your key
- Key: `AWS_SECRET_ACCESS_KEY`, Value: your secret

---

## Flow 06: Full Pipeline — S3 + Scheduled

**Purpose:** The complete, production-ready flow.

**File:** `flows/06_aws_s3_taxi_scheduled.yaml`

**Full pipeline:**
```
[Download Parquet from NYC TLC]
        ↓
[Upload raw parquet to S3] ─── (raw data lake)
        ↓
[Run Python: Load to PostgreSQL] ─── (analytical queries)
        ↓
[Log: rows inserted + S3 path]
```

**Parameterized with inputs:**
- `taxi_color`: green or yellow
- `year`: 2025
- `month`: 1-12

**Scheduled with cron:**
- Runs 5th of each month (data for previous month)

**Concurrency:** limit 1 (no overlapping runs)

---

## Error Handling in Kestra

### Retry on failure
```yaml
- id: download
  type: io.kestra.plugin.core.http.Download
  uri: "..."
  retry:
    type: constant
    interval: PT30S    # wait 30 seconds between retries
    maxAttempt: 3      # retry up to 3 times
```

### On failure task
```yaml
tasks:
  - id: main_task
    type: io.kestra.plugin.scripts.python.Script
    script: ...

errors:
  - id: alert_on_failure
    type: io.kestra.plugin.core.log.Log
    message: "Pipeline FAILED! Check execution {{ execution.id }}"
```

---

## Understanding Kestra Outputs and File Passing

This is the key difference from just running scripts manually:

```
Task A downloads file → stores in Kestra internal storage → returns URI
                                                                ↓
Task B receives URI via {{ outputs.taskA.uri }} → reads the file
                                                                ↓
Task C receives row count via {{ outputs.taskB.vars.count }} → logs it
```

**Data never leaves Kestra's control** — it manages the handoffs between tasks.  
This is what makes the pipeline **reliable and observable**.
