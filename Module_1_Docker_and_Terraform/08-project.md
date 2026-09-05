# 🚀 Module 1 Project: NYC Taxi Data Pipeline (Docker, PostgreSQL & AWS)

> **Complete End-to-End Data Pipeline with Docker, PostgreSQL, Python, SQL, and AWS (S3, Glue & Athena)**

---

## 🎯 Project Goal

Build a **complete, containerized data pipeline** that:
1. Orchestrates a local **PostgreSQL** database and **pgAdmin** web interface using Docker Compose.
2. Ingests NYC Green Taxi trip data (November 2025) using a containerized Python script.
3. Performs analytical SQL queries in PostgreSQL.
4. Provisions cloud infrastructure in **Amazon Web Services (AWS)** using **Terraform**:
   - **Amazon S3**: Scalable Data Lake.
   - **AWS Glue Data Catalog**: Metadata database.
   - **Amazon Athena**: Serverless SQL engine to query Parquet files directly in S3.
5. Uploads raw data to your AWS S3 Data Lake using Python (`boto3`).

---

## 🗺️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Local Machine (Docker)                            │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    Docker Network (`de_network`)                      │  │
│  │                                                                       │  │
│  │  ┌─────────────────────────┐         ┌──────────────────────────────┐ │  │
│  │  │  taxi_ingest            │         │  pgadmin                     │ │  │
│  │  │  (Python Ingestion)     │         │  (Web UI at localhost:8080)  │ │  │
│  │  └───────────┬─────────────┘         └──────────────┬───────────────┘ │  │
│  │              │ chunked insert                       │ queries         │  │
│  │              ▼                                      ▼                 │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │  │
│  │  │                     PostgreSQL Container (5432)                  │ │  │
│  │  │   Database: ny_taxi                                              │ │  │
│  │  │   Tables: green_taxi_trips, zones                                │ │  │
│  │  └──────────────────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                     │                                       │
│                                     │ python scripts/upload_to_s3.py        │
│                                     ▼                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                     Amazon Web Services (AWS Cloud)                   │  │
│  │                                                                       │  │
│  │   • Amazon S3 Bucket: s3://<bucket-name>/raw/ (Data Lake)             │  │
│  │   • AWS Glue Data Catalog: ny_taxi_db                                 │  │
│  │   • Amazon Athena: ny_taxi_workgroup (Serverless SQL Querying)        │  │
│  │                                                                       │  │
│  │                 Provisioned via Terraform (IaC)                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Directory Layout

All work lives in `nyc_taxi_pipeline/`:

```
nyc_taxi_pipeline/
│
├── Dockerfile                      ← Container image recipe for ingestion
├── docker-compose.yaml             ← Multi-container service definitions
├── requirements.txt                ← Python package dependencies
├── .env                            ← Local environment variables (never commit!)
├── .gitignore                      ← Files excluded from Git
├── README.md                       ← Execution manual
│
├── data/                           ← Local data download folder
│
├── scripts/
│   ├── ingest_data.py              ← Downloads data and ingests to PostgreSQL
│   └── upload_to_s3.py             ← Uploads raw data to Amazon S3 Data Lake
│
├── queries/
│   ├── analysis.sql                ← PostgreSQL analytical queries
│   ├── homework.sql                ← Module 1 homework SQL queries
│   └── athena_queries.sql          ← SQL queries executed in Amazon Athena
│
└── terraform/
    ├── main.tf                     ← AWS S3 + Glue + Athena resource definitions
    ├── variables.tf                ← Variables (region, bucket name, db name)
    └── .gitignore                  ← Ignores .tfstate and secrets
```

---

## 🛠️ Step 1: Python Dependencies (`requirements.txt`)

```text
pandas
sqlalchemy
psycopg2-binary
pyarrow
requests
boto3
```

---

## ⚙️ Step 2: Environment Variables (`.env`)

```dotenv
POSTGRES_USER=root
POSTGRES_PASSWORD=root
POSTGRES_DB=ny_taxi
PGADMIN_EMAIL=admin@admin.com
PGADMIN_PASSWORD=root
DATA_URL=https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
ZONES_URL=https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv

# ── AWS Settings ──────────────────────────────
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
S3_BUCKET_NAME=ny-taxi-data-lake-unique-12345
```

---

## 🐳 Step 3: Container Definition (`Dockerfile`)

```dockerfile
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
```

---

## 🐙 Step 4: Multi-Container Setup (`docker-compose.yaml`)

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:17-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    networks:
      - de_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD}
    ports:
      - "8080:80"
    volumes:
      - ./pgadmin_data:/var/lib/pgadmin
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - de_network

  ingest:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: taxi_ingest
    command: >
      --user=${POSTGRES_USER}
      --password=${POSTGRES_PASSWORD}
      --host=postgres
      --port=5432
      --db=${POSTGRES_DB}
      --table_name=green_taxi_trips
      --url=${DATA_URL}
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - de_network

networks:
  de_network:
    driver: bridge
```

---

## 🐍 Step 5: Data Ingestion (`scripts/ingest_data.py`)

```python
#!/usr/bin/env python3
"""
NYC Taxi Data Ingestion Script
Downloads CSV/Parquet from URL and loads it into PostgreSQL in chunks
"""

import argparse
import os
import pandas as pd
from sqlalchemy import create_engine
from time import time


def download_file(url, output_path):
    print(f"\n[Step 1] Downloading file from: {url}")
    os.system(f"wget '{url}' -O '{output_path}' -q --show-progress")
    print(f"  Downloaded: {output_path}")
    return output_path


def read_data(file_path):
    print(f"\n[Step 2] Reading file: {file_path}")
    if file_path.endswith(".parquet"):
        df = pd.read_parquet(file_path)
    else:
        df = pd.read_csv(file_path, compression="infer")
    print(f"  Loaded {len(df):,} rows with {len(df.columns)} columns.")
    return df


def fix_datetimes(df):
    print(f"\n[Step 3] Parsing datetime columns...")
    datetime_cols = [col for col in df.columns if "datetime" in col.lower()]
    for col in datetime_cols:
        df[col] = pd.to_datetime(df[col])
        print(f"  Parsed {col}")
    return df


def load_to_postgres(df, table_name, engine, chunk_size=100000):
    print(f"\n[Step 4] Loading into PostgreSQL table '{table_name}'...")
    total_rows = len(df)

    # 1. Create table structure with 0 rows
    df.head(0).to_sql(name=table_name, con=engine, if_exists="replace", index=False)
    print(f"  Table structure created.")

    # 2. Insert data in chunks
    for start in range(0, total_rows, chunk_size):
        t_start = time()
        chunk = df.iloc[start : start + chunk_size]
        chunk.to_sql(name=table_name, con=engine, if_exists="append", index=False)
        t_end = time()

        rows_done = min(start + chunk_size, total_rows)
        print(f"  {rows_done:,} / {total_rows:,} rows inserted ({t_end - t_start:.2f}s)")

    print(f"\n✅ All {total_rows:,} rows loaded successfully!")


def main(params):
    conn_str = f"postgresql://{params.user}:{params.password}@{params.host}:{params.port}/{params.db}"
    engine = create_engine(conn_str)
    print(f"Connected to database: {params.host}:{params.port}/{params.db}")

    os.makedirs("data", exist_ok=True)
    local_file = "data/temp_data.parquet" if params.url.endswith(".parquet") else "data/temp_data.csv.gz"

    download_file(params.url, local_file)
    df = read_data(local_file)
    df = fix_datetimes(df)
    load_to_postgres(df, params.table_name, engine)

    # Clean up temporary local file
    if os.path.exists(local_file):
        os.remove(local_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest data into PostgreSQL")
    parser.add_argument("--user", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True)
    parser.add_argument("--db", required=True)
    parser.add_argument("--table_name", required=True)
    parser.add_argument("--url", required=True)

    args = parser.parse_args()
    main(args)
```

---

## ☁️ Step 6: Amazon S3 Uploader (`scripts/upload_to_s3.py`)

```python
#!/usr/bin/env python3
"""
Upload a local file to an Amazon S3 Bucket (AWS Data Lake)
"""

import argparse
import boto3
from botocore.exceptions import ClientError, NoCredentialsError


def upload_to_s3(bucket_name, local_file_path, destination_s3_key, region="us-east-1"):
    print(f"\n[S3 Upload] Starting upload...")
    print(f"  Source: {local_file_path}")
    print(f"  Target: s3://{bucket_name}/{destination_s3_key}")

    # Boto3 automatically reads AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY from env or ~/.aws/credentials
    s3_client = boto3.client("s3", region_name=region)

    try:
        s3_client.upload_file(local_file_path, bucket_name, destination_s3_key)
        print(f"✅ Successfully uploaded to s3://{bucket_name}/{destination_s3_key}")
    except FileNotFoundError:
        print(f"❌ Error: Local file '{local_file_path}' not found.")
    except NoCredentialsError:
        print("❌ Error: AWS credentials not found. Run 'aws configure' or check your .env file.")
    except ClientError as e:
        print(f"❌ AWS Client Error: {e}")


def main():
    parser = argparse.ArgumentParser(description="Upload file to Amazon S3")
    parser.add_argument("--bucket",     required=True, help="S3 bucket name")
    parser.add_argument("--local_file", required=True, help="Path to local file")
    parser.add_argument("--s3_key",     required=True, help="Destination key in S3")
    parser.add_argument("--region",     default="us-east-1", help="AWS region")

    args = parser.parse_args()
    upload_to_s3(args.bucket, args.local_file, args.s3_key, args.region)


if __name__ == "__main__":
    main()
```

---

## 🏗️ Step 7: AWS Infrastructure with Terraform

### `terraform/main.tf`

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Amazon S3 Data Lake Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket        = var.s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "data_lake_versioning" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake_lifecycle" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "expire-old-files-after-30-days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# 2. AWS Glue Catalog Database (Metadata & Schema store)
resource "aws_glue_catalog_database" "taxi_database" {
  name        = var.glue_database_name
  description = "Glue Catalog Database for NYC Taxi dataset"
}

# 3. Amazon Athena Workgroup & Results Bucket
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.s3_bucket_name}-athena-results"
  force_destroy = true
}

resource "aws_athena_workgroup" "taxi_workgroup" {
  name          = "ny_taxi_workgroup"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/output/"
    }
  }
}
```

### `terraform/variables.tf`

```hcl
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Globally unique Amazon S3 bucket name"
  type        = string
  default     = "ny-taxi-data-lake-unique-12345" # Replace with your unique name
}

variable "glue_database_name" {
  description = "Name of the Glue Data Catalog database"
  type        = string
  default     = "ny_taxi_db"
}
```

---

## 📊 Step 8: Querying with Amazon Athena (`queries/athena_queries.sql`)

Once your data is uploaded to S3 and your Glue database is created via Terraform, open **Amazon Athena** in the AWS Console and run:

```sql
-- 1. Create external table pointing directly to S3 data lake
CREATE EXTERNAL TABLE IF NOT EXISTS ny_taxi_db.green_taxi_trips (
    VendorID INT,
    lpep_pickup_datetime TIMESTAMP,
    lpep_dropoff_datetime TIMESTAMP,
    passenger_count INT,
    trip_distance DOUBLE,
    total_amount DOUBLE,
    PULocationID INT,
    DOLocationID INT
)
STORED AS PARQUET
LOCATION 's3://YOUR-S3-BUCKET-NAME/raw/';

-- 2. Query total trip count directly from S3
SELECT COUNT(*) AS total_trips
FROM ny_taxi_db.green_taxi_trips;

-- 3. Daily trips and revenue directly over S3
SELECT
    DATE_TRUNC('day', lpep_pickup_datetime) AS pickup_day,
    COUNT(*)                                AS trips,
    ROUND(SUM(total_amount), 2)             AS revenue
FROM ny_taxi_db.green_taxi_trips
GROUP BY 1
ORDER BY 1;
```

---

## 🚀 Execution Checklist

```bash
# 1. Start Postgres and pgAdmin + run ingestion container
cd nyc_taxi_pipeline
docker-compose up -d

# 2. Monitor ingestion progress
docker logs -f taxi_ingest

# 3. Access pgAdmin at http://localhost:8080
#    (Login: admin@admin.com / root | Host: postgres | Port: 5432 | DB: ny_taxi)

# 4. Ingest the lookup zones table
python scripts/ingest_data.py \
  --user root --password root --host localhost --port 5432 \
  --db ny_taxi --table_name zones \
  --url https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv

# 5. Provision your AWS cloud infrastructure:
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# 6. Upload data to Amazon S3 Data Lake:
python scripts/upload_to_s3.py \
  --bucket YOUR-S3-BUCKET-NAME \
  --local_file data/green_tripdata_2025-11.parquet \
  --s3_key raw/green_tripdata_2025-11.parquet

# 7. When finished with learning:
docker-compose down
cd terraform && terraform destroy -auto-approve
```

---

*Previous: [Topic 7 - Terraform](07-terraform-concepts.md) | Next: [Homework →](09-homework.md)*
