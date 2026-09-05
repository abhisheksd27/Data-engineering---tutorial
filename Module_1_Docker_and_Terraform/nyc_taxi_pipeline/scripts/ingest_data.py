#!/usr/bin/env python3
"""
NYC Taxi Data Ingestion Script
Downloads a CSV or Parquet file and loads it into PostgreSQL in chunks
"""

import argparse
import os
import pandas as pd
from sqlalchemy import create_engine
from time import time


def download_file(url, output_path):
    print(f"\n[Step 1] Downloading file from:\n  {url}")
    os.system(f"wget '{url}' -O '{output_path}' -q --show-progress")
    print(f"  Finished downloading to: {output_path}")
    return output_path


def read_data(file_path):
    print(f"\n[Step 2] Reading data from {file_path}...")
    if file_path.endswith('.parquet'):
        df = pd.read_parquet(file_path)
    elif file_path.endswith('.csv') or file_path.endswith('.csv.gz'):
        df = pd.read_csv(file_path, compression='infer')
    else:
        raise ValueError(f"Unsupported file format: {file_path}. Please provide a CSV or Parquet file.")
    print(f"  Loaded {len(df):,} rows with {len(df.columns)} columns.")
    return df


def fix_datetime(df):
    print("\n[Step 3] Fixing datetime columns...")
    datetime_columns = [col for col in df.columns if 'datetime' in col.lower()]
    for col in datetime_columns:
        df[col] = pd.to_datetime(df[col])
        print(f"  Parsed {col}")
    print("  Finished fixing datetime columns.")
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
        pct = (rows_done / total_rows) * 100
        print(f"  {rows_done:,} / {total_rows:,} rows ({pct:.1f}%) — took {t_end - t_start:.2f}s")

    print(f"\n✅ All {total_rows:,} rows loaded successfully into '{table_name}'!")


def main(params):
    conn_str = f"postgresql://{params.user}:{params.password}@{params.host}:{params.port}/{params.db}"
    engine = create_engine(conn_str)
    print(f"Connected to database: {params.host}:{params.port}/{params.db}")

    os.makedirs("data", exist_ok=True)
    if params.url.endswith(".parquet"):
        local_file = "data/temp_data.parquet"
    elif params.url.endswith(".csv.gz") or params.url.endswith(".gz"):
        local_file = "data/temp_data.csv.gz"
    else:
        local_file = "data/temp_data.csv"

    download_file(params.url, local_file)
    df = read_data(local_file)
    df = fix_datetime(df)
    load_to_postgres(df, params.table_name, engine)

    # Clean up temporary local file
    if os.path.exists(local_file):
        os.remove(local_file)
        print(f"Temporary file {local_file} cleaned up.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest data into PostgreSQL")
    parser.add_argument("--user", required=True, help="PostgreSQL username")
    parser.add_argument("--password", required=True, help="PostgreSQL password")
    parser.add_argument("--host", required=True, help="PostgreSQL host")
    parser.add_argument("--port", required=True, help="PostgreSQL port")
    parser.add_argument("--db", required=True, help="Database name")
    parser.add_argument("--table_name", required=True, help="Target table name")
    parser.add_argument("--url", required=True, help="URL to download data from")

    args = parser.parse_args()
    main(args)