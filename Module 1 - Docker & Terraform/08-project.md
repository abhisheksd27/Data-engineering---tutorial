# 🚀 Module 1 Project: NYC Taxi Data Pipeline

> **Full Local Data Pipeline combining ALL Module 1 topics**

---

## 🎯 Project Goal

Build a **complete, containerized, local data pipeline** that:
1. Downloads NYC Green Taxi trip data (November 2025)
2. Ingests it into PostgreSQL (running in Docker)
3. Runs analytical SQL queries
4. Provisions GCP infrastructure with Terraform (for future modules)

This project demonstrates how all Module 1 components work **together**.

---

## 🗺️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Your Machine                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  Docker Network                          │   │
│  │                                                          │   │
│  │  ┌─────────────────┐    ┌──────────────────────────┐    │   │
│  │  │  taxi_ingest    │    │     pgadmin              │    │   │
│  │  │  (Python script)│    │  (Web UI: localhost:8080) │   │   │
│  │  │                 │    │                          │    │   │
│  │  └────────┬────────┘    └──────────┬───────────────┘   │   │
│  │           │ loads data             │ queries            │   │
│  │           ↓                        ↓                    │   │
│  │  ┌──────────────────────────────────────────────────┐   │   │
│  │  │              PostgreSQL (port 5432)              │   │   │
│  │  │   Database: ny_taxi                              │   │   │
│  │  │   Tables: green_taxi_trips, zones               │   │   │
│  │  └──────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌───────────────────────────────────┐                          │
│  │  Terraform                        │                          │
│  │  (provisions GCP resources)       │ ──→  Google Cloud        │
│  │  ├── GCS Bucket (Data Lake)       │      Platform            │
│  │  └── BigQuery Dataset (Warehouse) │                          │
│  └───────────────────────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Folder Structure

```
module1-project/
│
├── docker-compose.yaml      ← Defines all containers
├── Dockerfile               ← Ingestion script image
├── ingest_data.py           ← Main ingestion script
├── requirements.txt         ← Python dependencies
│
├── terraform/
│   ├── main.tf              ← GCP resources
│   ├── variables.tf         ← Variable definitions
│   └── .gitignore           ← Ignore state files & creds
│
├── queries/
│   ├── analysis.sql         ← Analytical queries
│   └── homework.sql         ← Homework answer queries
│
└── README.md                ← Project documentation
```

---

## ⚙️ Part 1: Setup with Docker Compose

### `docker-compose.yaml`

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:17-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: 'root'
      POSTGRES_PASSWORD: 'root'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5432:5432'
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    networks:
      - de_network

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: "admin@admin.com"
      PGADMIN_DEFAULT_PASSWORD: "root"
    ports:
      - "8080:80"
    volumes:
      - ./pgadmin_data:/var/lib/pgadmin
    depends_on:
      - postgres
    networks:
      - de_network

  ingest:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: taxi_ingest
    command: >
      --user=root
      --password=root
      --host=postgres
      --port=5432
      --db=ny_taxi
      --table_name=green_taxi_trips
      --url=https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
    depends_on:
      - postgres
    networks:
      - de_network

networks:
  de_network:
    driver: bridge
```

---

## 🐍 Part 2: Ingestion Script

### `requirements.txt`

```
pandas
sqlalchemy
psycopg2-binary
pyarrow
requests
```

### `Dockerfile`

```dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ingest_data.py .

ENTRYPOINT ["python", "ingest_data.py"]
```

### `ingest_data.py`

```python
#!/usr/bin/env python3
"""
NYC Taxi Data Ingestion Script
Loads data from URL (CSV or Parquet) into PostgreSQL
"""

import argparse
import os
import pandas as pd
from sqlalchemy import create_engine
from time import time


def download_file(url: str, output_path: str) -> str:
    """Download a file from URL to local path."""
    print(f"Downloading: {url}")
    os.system(f"wget '{url}' -O '{output_path}'")
    print(f"Downloaded to: {output_path}")
    return output_path


def read_data(file_path: str) -> pd.DataFrame:
    """Read data from CSV or Parquet file."""
    if file_path.endswith('.parquet'):
        print("Reading Parquet file...")
        df = pd.read_parquet(file_path)
    else:
        print("Reading CSV file...")
        df = pd.read_csv(file_path, compression='infer')
    
    print(f"Shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    return df


def fix_datetime_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Parse datetime columns."""
    datetime_cols = [col for col in df.columns if 'datetime' in col.lower()]
    for col in datetime_cols:
        df[col] = pd.to_datetime(df[col])
        print(f"  Parsed datetime column: {col}")
    return df


def ingest_to_postgres(
    df: pd.DataFrame,
    table_name: str,
    engine,
    chunk_size: int = 100000
) -> None:
    """Load DataFrame into PostgreSQL in chunks."""
    
    # Create table structure (empty)
    df.head(0).to_sql(name=table_name, con=engine, if_exists='replace')
    print(f"Table '{table_name}' created.")
    
    # Insert in chunks
    total_rows = len(df)
    chunks_inserted = 0
    
    for start in range(0, total_rows, chunk_size):
        t_start = time()
        chunk = df.iloc[start:start + chunk_size]
        chunk.to_sql(name=table_name, con=engine, if_exists='append', index=False)
        t_end = time()
        
        chunks_inserted += 1
        rows_done = min(start + chunk_size, total_rows)
        print(f"  Chunk {chunks_inserted}: {rows_done}/{total_rows} rows "
              f"({t_end - t_start:.2f}s)")
    
    print(f"\nTotal rows inserted: {total_rows}")


def main(params):
    # Connection string
    connection_str = (
        f'postgresql://{params.user}:{params.password}'
        f'@{params.host}:{params.port}/{params.db}'
    )
    engine = create_engine(connection_str)
    
    print(f"Connected to: {params.host}:{params.port}/{params.db}")
    
    # Determine file extension
    if params.url.endswith('.parquet'):
        local_file = 'data.parquet'
    else:
        local_file = 'data.csv.gz'
    
    # Download
    download_file(params.url, local_file)
    
    # Read
    df = read_data(local_file)
    
    # Fix datetimes
    df = fix_datetime_columns(df)
    
    # Ingest
    ingest_to_postgres(df, params.table_name, engine)
    
    print(f"\n✅ Data successfully loaded into table '{params.table_name}'")
    
    # Cleanup
    os.remove(local_file)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ingest data to Postgres')
    parser.add_argument('--user', required=True, help='PostgreSQL username')
    parser.add_argument('--password', required=True, help='PostgreSQL password')
    parser.add_argument('--host', required=True, help='PostgreSQL host')
    parser.add_argument('--port', required=True, help='PostgreSQL port')
    parser.add_argument('--db', required=True, help='Database name')
    parser.add_argument('--table_name', required=True, help='Target table name')
    parser.add_argument('--url', required=True, help='URL to download data from')
    
    args = parser.parse_args()
    main(args)
```

---

## 🔍 Part 3: Analytical SQL Queries

### `queries/analysis.sql`

```sql
-- ============================================================
-- NYC Green Taxi Data Analysis (November 2025)
-- ============================================================

-- 1. How many total trips?
SELECT COUNT(*) AS total_trips
FROM green_taxi_trips;

-- 2. Date range of the data
SELECT 
    MIN(lpep_pickup_datetime) AS earliest_trip,
    MAX(lpep_pickup_datetime) AS latest_trip
FROM green_taxi_trips;

-- 3. Trips per day
SELECT
    CAST(lpep_pickup_datetime AS DATE) AS pickup_date,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount)::numeric, 2) AS revenue
FROM green_taxi_trips
GROUP BY pickup_date
ORDER BY pickup_date;

-- 4. Top 5 pickup zones by number of trips
SELECT
    z."Zone" AS pickup_zone,
    z."Borough",
    COUNT(*) AS trip_count
FROM green_taxi_trips t
JOIN zones z ON t."PULocationID" = z."LocationID"
GROUP BY z."Zone", z."Borough"
ORDER BY trip_count DESC
LIMIT 5;

-- 5. Average fare by trip distance range
SELECT
    CASE
        WHEN trip_distance <= 1 THEN '0-1 miles'
        WHEN trip_distance <= 5 THEN '1-5 miles'
        WHEN trip_distance <= 10 THEN '5-10 miles'
        ELSE '10+ miles'
    END AS distance_range,
    COUNT(*) AS trips,
    ROUND(AVG(total_amount)::numeric, 2) AS avg_fare
FROM green_taxi_trips
WHERE trip_distance > 0
GROUP BY distance_range
ORDER BY avg_fare;

-- 6. Rush hour analysis
SELECT
    DATE_PART('hour', lpep_pickup_datetime) AS hour_of_day,
    COUNT(*) AS trips,
    ROUND(AVG(total_amount)::numeric, 2) AS avg_fare
FROM green_taxi_trips
GROUP BY hour_of_day
ORDER BY hour_of_day;
```

---

## 🏗️ Part 4: Terraform GCP Setup

### `terraform/main.tf`

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}

# Data Lake: Google Cloud Storage Bucket
resource "google_storage_bucket" "data_lake" {
  name          = "${var.project}-data-lake"
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }
}

# Data Warehouse: BigQuery Dataset
resource "google_bigquery_dataset" "warehouse" {
  dataset_id    = var.bq_dataset_name
  friendly_name = "NY Taxi Warehouse"
  description   = "Data Engineering Zoomcamp Dataset"
  location      = var.location
  
  delete_contents_on_destroy = true
}
```

### Running Terraform

```bash
cd terraform/

# 1. Initialize
terraform init

# 2. Preview
terraform plan

# 3. Apply
terraform apply -auto-approve

# 4. Verify in GCP Console!

# 5. When done with the course
terraform destroy -auto-approve
```

---

## 🚀 Running the Complete Project

### Step 1: Clone the zoomcamp repo

```bash
git clone https://github.com/DataTalksClub/data-engineering-zoomcamp.git
cd data-engineering-zoomcamp/01-docker-terraform
```

### Step 2: Start the infrastructure

```bash
# Build images and start all containers
docker-compose up -d

# Check everything is running
docker-compose ps
```

### Step 3: Load zones data separately

```bash
# Connect to Postgres and load zones
python3 -c "
import pandas as pd
from sqlalchemy import create_engine
import requests

engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')
df = pd.read_csv('https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv')
df.to_sql('zones', engine, if_exists='replace', index=False)
print(f'Zones loaded: {len(df)} rows')
"
```

### Step 4: Access pgAdmin

1. Open: http://localhost:8080
2. Login: admin@admin.com / root
3. Add server: host=`postgres`, port=`5432`, db=`ny_taxi`

### Step 5: Run queries

Open pgAdmin Query Tool and paste from `queries/analysis.sql`

### Step 6: Provision GCP (optional)

```bash
cd terraform/
terraform init && terraform apply
```

### Step 7: Cleanup

```bash
# Stop containers
docker-compose down

# Destroy GCP resources
cd terraform && terraform destroy
```

---

## ✅ Project Checklist

```
[ ] Docker Desktop installed and running
[ ] docker-compose up -d (all containers healthy)
[ ] pgAdmin accessible at localhost:8080
[ ] green_taxi_trips table populated with Nov 2025 data
[ ] zones table populated (265 rows)
[ ] All 6 analysis queries run successfully
[ ] GCP account set up with free trial
[ ] Service account created with JSON key
[ ] terraform init && plan && apply successful
[ ] GCS bucket visible in GCP Console
[ ] BigQuery dataset visible in GCP Console
[ ] terraform destroy run (no lingering costs)
```

---

## 🔗 How Module 1 Feeds Into Later Modules

| Module 1 skill | Used in... |
|---------------|-----------|
| Docker containers | Module 2: Kestra runs in Docker |
| PostgreSQL & SQL | Module 3: BigQuery (same SQL syntax) |
| Python data ingestion | Module 2: Kestra pipelines replace this |
| GCS bucket (Terraform) | Module 2, 5: Store pipeline data |
| BigQuery dataset (Terraform) | Module 3, 4, 6: All cloud analytics |

---

*Previous: [Topic 7 - Terraform](07-terraform-concepts.md) | Next: [Homework →](09-homework.md)*
