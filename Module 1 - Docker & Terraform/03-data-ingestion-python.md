# 🐍 Topic 3: Data Ingestion with Python

> **GitHub**: [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql)  
> **Video**: [Docker + Postgres Workshop](https://www.youtube.com/watch?v=lP8xXebHmuE)

---

## 🤔 What is Data Ingestion?

**Data Ingestion** = The process of loading raw data from a source into a storage system (database, data lake, warehouse).

In this module, we:
1. **Download** NYC Yellow Taxi trip data (CSV/Parquet)
2. **Transform** it using `pandas` (minimal, just reading)
3. **Load** it into PostgreSQL using `SQLAlchemy`

This is a simple **ETL pipeline**:
```
Extract (download) → Transform (clean/parse) → Load (insert into DB)
```

---

## 📦 Tools We Use

| Tool | Purpose |
|------|---------|
| `pandas` | Read CSV/Parquet, chunk data |
| `sqlalchemy` | Python DB connection library |
| `psycopg2` | PostgreSQL driver |
| `wget` / `requests` | Download data |

Install dependencies:

```bash
pip install pandas sqlalchemy psycopg2-binary
```

---

## 📥 Step 1: Download the NYC Taxi Data

The dataset used in this course is the **NYC TLC (Taxi & Limousine Commission)** trip data.

```bash
# Download Yellow Taxi data (January 2021 example)
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz

# Download the zones lookup table
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

For the 2025 homework (Green Taxi data):
```bash
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

---

## 🔍 Step 2: Explore Data in Jupyter

Before loading, always **explore your data**:

```python
import pandas as pd

# Read the CSV
df = pd.read_csv('yellow_tripdata_2021-01.csv.gz', nrows=100)

# Or read Parquet (newer format)
df = pd.read_parquet('green_tripdata_2025-11.parquet')

# Explore
print(df.shape)           # (rows, columns)
print(df.dtypes)          # Data types
print(df.head())          # First 5 rows
print(df.isnull().sum())  # Missing values
```

---

## 🏗️ Step 3: Create the Database Table

```python
from sqlalchemy import create_engine

# Connect to PostgreSQL
engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')

# Generate CREATE TABLE SQL from DataFrame (without inserting data)
print(pd.io.sql.get_schema(df, name='yellow_taxi_trips', con=engine))
```

Output (example):
```sql
CREATE TABLE yellow_taxi_trips (
    "VendorID" BIGINT,
    "tpep_pickup_datetime" TEXT,
    "tpep_dropoff_datetime" TEXT,
    "passenger_count" FLOAT(53),
    "trip_distance" FLOAT(53),
    ...
)
```

### Fix datetime columns

```python
# Parse datetime columns properly
df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
```

---

## 📤 Step 4: Load Data in Chunks

The NYC Taxi dataset has **millions of rows**. We load it in **chunks** to avoid memory issues:

```python
import pandas as pd
from sqlalchemy import create_engine
from time import time

engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')

# Read CSV in chunks of 100,000 rows
df_iter = pd.read_csv(
    'yellow_tripdata_2021-01.csv.gz',
    iterator=True,
    chunksize=100000
)

# First chunk: create the table (if_exists='replace' drops and recreates)
df = next(df_iter)
df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

# Insert headers only (0 rows) to create table structure
df.head(0).to_sql(
    name='yellow_taxi_trips',
    con=engine,
    if_exists='replace'
)

# Insert first chunk
df.to_sql(
    name='yellow_taxi_trips',
    con=engine,
    if_exists='append'
)

# Insert remaining chunks
while True:
    try:
        t_start = time()
        df = next(df_iter)

        df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
        df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

        df.to_sql(name='yellow_taxi_trips', con=engine, if_exists='append')

        t_end = time()
        print(f'Inserted chunk, took {t_end - t_start:.3f} seconds')
    except StopIteration:
        print('All chunks inserted!')
        break
```

---

## 🗂️ Step 5: Load the Zones Lookup Table

```python
df_zones = pd.read_csv('taxi_zone_lookup.csv')
print(df_zones.head())
#    LocationID        Borough                    Zone service_zone
# 0           1            EWR             Newark Airport          EWR
# 1           2         Queens              Jamaica Bay    Boro Zone
# 2           3          Bronx  Allerton/Pelham Gardens    Boro Zone

df_zones.to_sql(name='zones', con=engine, if_exists='replace')
print("Zones loaded!")
```

---

## 📦 Step 6: Containerize the Ingestion Script

Now we turn the ingestion script into a Docker container that can be run anywhere:

**`ingest_data.py`** (command-line version):

```python
#!/usr/bin/env python
import argparse
import pandas as pd
from sqlalchemy import create_engine
from time import time

def main(params):
    user = params.user
    password = params.password
    host = params.host
    port = params.port
    db = params.db
    table_name = params.table_name
    url = params.url

    # Download the file
    csv_name = 'output.csv'
    os.system(f"wget {url} -O {csv_name}")

    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{db}')

    df_iter = pd.read_csv(csv_name, iterator=True, chunksize=100000)

    df = next(df_iter)
    df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
    df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)

    df.head(0).to_sql(name=table_name, con=engine, if_exists='replace')
    df.to_sql(name=table_name, con=engine, if_exists='append')

    while True:
        try:
            t_start = time()
            df = next(df_iter)
            df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
            df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
            df.to_sql(name=table_name, con=engine, if_exists='append')
            t_end = time()
            print(f'Inserted chunk, took {(t_end - t_start):.3f} second')
        except StopIteration:
            print('Completed!')
            break

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ingest CSV data to Postgres')
    parser.add_argument('--user', required=True)
    parser.add_argument('--password', required=True)
    parser.add_argument('--host', required=True)
    parser.add_argument('--port', required=True)
    parser.add_argument('--db', required=True)
    parser.add_argument('--table_name', required=True)
    parser.add_argument('--url', required=True)
    args = parser.parse_args()
    main(args)
```

**`Dockerfile`** for the ingestion script:

```dockerfile
FROM python:3.9

RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2

WORKDIR /app
COPY ingest_data.py ingest_data.py

ENTRYPOINT ["python", "ingest_data.py"]
```

**Build and Run:**

```bash
# Build the ingestion image
docker build -t taxi_ingest:v001 .

# Run the ingestion container (connected to the Postgres network)
docker run -it \
  --network=pg-network \
  taxi_ingest:v001 \
    --user=root \
    --password=root \
    --host=pg-database \
    --port=5432 \
    --db=ny_taxi \
    --table_name=yellow_taxi_trips \
    --url=http://your-data-url/yellow_tripdata_2021-01.csv.gz
```

> 💡 The ingestion container uses `--host=pg-database` (container name) to reach Postgres on the same Docker network!

---

## 📊 Data Flow Architecture

```
Internet
   ↓ wget/requests
CSV/Parquet File (local disk)
   ↓ pandas.read_csv() / read_parquet()
pandas DataFrame (in memory, chunked)
   ↓ df.to_sql()
SQLAlchemy Connection
   ↓ psycopg2 driver
PostgreSQL Container (port 5432)
   ↓
ny_taxi database
   ↓ tables:
   ├── yellow_taxi_trips  (~1M+ rows)
   └── zones              (265 rows)
```

---

## ✅ Verify the Load

```python
# Quick verification query
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')

df = pd.read_sql("SELECT COUNT(*) FROM yellow_taxi_trips", engine)
print(df)
# count
# 1369765
```

---

*Previous: [Topic 2 - PostgreSQL with Docker](02-postgres-with-docker.md) | Next: [Topic 4 - Docker Compose →](04-docker-compose.md)*
