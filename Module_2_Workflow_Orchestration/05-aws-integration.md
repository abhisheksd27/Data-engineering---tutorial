# 05 — AWS Integration with Kestra

## Overview

In Module 1, we ran AWS CLI commands manually and used Python boto3 scripts.  
In Module 2, **Kestra handles all AWS interactions** — no more manual commands.

---

## Kestra AWS Plugin

Kestra has a dedicated AWS plugin suite:  
`io.kestra.plugin.aws.*`

Available AWS tasks:
| Plugin | AWS Service |
|---|---|
| `io.kestra.plugin.aws.s3.Upload` | Upload file to S3 |
| `io.kestra.plugin.aws.s3.Download` | Download file from S3 |
| `io.kestra.plugin.aws.s3.List` | List objects in S3 bucket |
| `io.kestra.plugin.aws.s3.Delete` | Delete S3 object |
| `io.kestra.plugin.aws.s3.Copy` | Copy between S3 paths |
| `io.kestra.plugin.aws.glue.CreateTable` | Create Glue catalog table |
| `io.kestra.plugin.aws.athena.Query` | Run SQL via Athena |

---

## Setting Up AWS Credentials in Kestra

### Method 1: KV Store (Recommended for local dev)

In Kestra UI → **KV Store** → Add:

| Key | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | `AKIA...` (your IAM key) |
| `AWS_SECRET_ACCESS_KEY` | your secret key |

Then reference in flows:
```yaml
pluginDefaults:
  - type: io.kestra.plugin.aws
    values:
      accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
      secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
      region: us-east-1
```

### Method 2: Environment Variables (via docker-compose)

In `docker-compose.yaml` under the Kestra service:
```yaml
environment:
  AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
  AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
  AWS_DEFAULT_REGION: us-east-1
```

Then in `.env`:
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=your_secret
```

---

## AWS S3 Upload Task

```yaml
- id: upload_to_s3
  type: io.kestra.plugin.aws.s3.Upload
  accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
  secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
  region: us-east-1
  bucket: ny-taxi-data-lake-abhishekshankar-826674
  key: "raw/{{ inputs.taxi_color }}_tripdata_{{ inputs.year }}-{{ '%02d' | format(inputs.month) }}.parquet"
  from: "{{ outputs.download_file.uri }}"
```

**After upload, outputs available:**
- `outputs.upload_to_s3.bucket` — bucket name
- `outputs.upload_to_s3.key` — S3 key of uploaded file
- `outputs.upload_to_s3.uri` — full S3 URI (`s3://bucket/key`)

---

## AWS Athena Query Task

```yaml
- id: run_athena_query
  type: io.kestra.plugin.aws.athena.Query
  accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
  secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
  region: us-east-1
  database: ny_taxi_db
  outputLocation: s3://ny-taxi-data-lake-abhishekshankar-826674-athena-results/kestra/
  query: |
    SELECT COUNT(*) as total_trips
    FROM green_taxi_trips
    WHERE year = {{ inputs.year }}
      AND month = {{ inputs.month }}
```

**Athena plugin waits** for the query to complete and returns results as outputs.

---

## Full Pipeline Architecture (Module 2 Final State)

```
[Kestra Scheduler — 5th of each month]
              ↓
[TASK 1: HTTP Download]
  URL: https://d37ci6vzurychx.cloudfront.net/trip-data/
       green_tripdata_{year}-{month}.parquet
  → output: parquet file URI in Kestra storage
              ↓
[TASK 2: S3 Upload]
  → s3://ny-taxi-data-lake-abhishekshankar-826674/raw/green_tripdata_{year}-{month}.parquet
  → output: S3 URI
              ↓
[TASK 3: Python Script — Load to PostgreSQL]
  → reads from Kestra file URI
  → pandas.read_parquet()
  → SQLAlchemy → PostgreSQL (ny_taxi DB)
  → output: row count
              ↓
[TASK 4: Log Summary]
  → "Loaded {row_count} rows | S3: {s3_uri}"
```

---

## S3 Folder Structure (Data Lake Layers)

Our S3 bucket follows a **Bronze/Silver/Gold** pattern (also called Raw/Staging/Analytics):

```
s3://ny-taxi-data-lake-abhishekshankar-826674/
├── raw/                          ← Bronze: original parquet files (from Kestra)
│   ├── green_tripdata_2025-01.parquet
│   ├── green_tripdata_2025-11.parquet
│   └── yellow_tripdata_2025-11.parquet
├── lookup/                       ← Lookup tables
│   └── taxi_zone_lookup.csv
└── athena-results/               ← Athena query output (separate bucket ideally)
```

---

## Kestra + Glue: Create External Table Automatically

When new data lands in S3, Kestra can automatically create/update the Glue catalog:

```yaml
- id: create_glue_table
  type: io.kestra.plugin.aws.glue.CreateTable
  accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
  secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
  region: us-east-1
  database: ny_taxi_db
  table: green_taxi_trips
  format: PARQUET
  location: "s3://ny-taxi-data-lake-abhishekshankar-826674/raw/"
  columns:
    - name: VendorID
      type: INT
    - name: lpep_pickup_datetime
      type: TIMESTAMP
    - name: total_amount
      type: DOUBLE
```

---

## IAM Requirements (Same as Module 1)

Your IAM user `abhishekshankar` needs:
- `AmazonS3FullAccess`
- `AmazonAthenaFullAccess`
- `AWSGlueConsoleFullAccess`

These were already set up in Module 1 — no changes needed.

---

## Comparing Module 1 vs Module 2 (AWS Interaction)

| Action | Module 1 (Manual) | Module 2 (Kestra) |
|---|---|---|
| Upload to S3 | `python scripts/upload_to_s3.py` | `io.kestra.plugin.aws.s3.Upload` task |
| Create Athena table | `aws athena start-query-execution` | `io.kestra.plugin.aws.athena.Query` task |
| Schedule monthly | Cron job / remember manually | Kestra schedule trigger |
| Error handling | None (script fails silently) | Retry + `errors:` block in flow |
| Observability | Check terminal output | Kestra UI: logs, duration, status |
| Backfill | Run script manually for each month | Kestra Backfill in UI |
