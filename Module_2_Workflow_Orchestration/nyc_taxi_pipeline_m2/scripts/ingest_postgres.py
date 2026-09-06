"""
ingest_postgres.py
------------------
Python script called by Kestra tasks (Flow 03 & 04).
Reads a parquet file and loads it into PostgreSQL.

Usage (standalone):
    python ingest_postgres.py \
        --file data.parquet \
        --table green_taxi_trips \
        --taxi_color green \
        --year 2025 \
        --month 11
"""

import argparse
import pandas as pd
from sqlalchemy import create_engine
import os


def ingest(file_path: str, table_name: str, taxi_color: str, year: int, month: int):
    """Read parquet file and load into PostgreSQL."""

    print(f"Reading: {file_path}")
    df = pd.read_parquet(file_path)

    # Standardize column names to lowercase
    df.columns = df.columns.str.lower()

    # Add partition columns
    df["year"] = year
    df["month"] = month

    # Normalize datetime columns (different column names for green vs yellow)
    pickup_col = "lpep_pickup_datetime" if taxi_color == "green" else "tpep_pickup_datetime"
    dropoff_col = "lpep_dropoff_datetime" if taxi_color == "green" else "tpep_dropoff_datetime"

    if pickup_col in df.columns:
        df[pickup_col] = pd.to_datetime(df[pickup_col])
        df[dropoff_col] = pd.to_datetime(df[dropoff_col])

    total_rows = len(df)
    print(f"Total rows: {total_rows} | Columns: {list(df.columns)}")

    # Connect to PostgreSQL
    postgres_host = os.getenv("POSTGRES_HOST", "localhost")
    postgres_port = os.getenv("POSTGRES_PORT", "5432")
    postgres_user = os.getenv("POSTGRES_USER", "root")
    postgres_password = os.getenv("POSTGRES_PASSWORD", "root")
    postgres_db = os.getenv("POSTGRES_DB", "ny_taxi")

    conn_str = f"postgresql://{postgres_user}:{postgres_password}@{postgres_host}:{postgres_port}/{postgres_db}"
    engine = create_engine(conn_str)

    print(f"Connecting to PostgreSQL: {postgres_host}:{postgres_port}/{postgres_db}")

    # Write in chunks to avoid memory issues
    chunk_size = 10_000
    for i in range(0, total_rows, chunk_size):
        chunk = df.iloc[i : i + chunk_size]
        chunk.to_sql(
            table_name,
            engine,
            if_exists="replace" if i == 0 else "append",
            index=False,
        )
        pct = min(i + chunk_size, total_rows)
        print(f"  Inserted rows {i} – {pct} ({pct}/{total_rows})")

    print(f"\n✅ Done! {total_rows} rows → table '{table_name}'")
    return total_rows


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest parquet file into PostgreSQL")
    parser.add_argument("--file", required=True, help="Path to parquet file")
    parser.add_argument("--table", default="green_taxi_trips", help="Target PostgreSQL table name")
    parser.add_argument("--taxi_color", default="green", choices=["green", "yellow"])
    parser.add_argument("--year", type=int, default=2025)
    parser.add_argument("--month", type=int, default=11)
    args = parser.parse_args()

    ingest(
        file_path=args.file,
        table_name=args.table,
        taxi_color=args.taxi_color,
        year=args.year,
        month=args.month,
    )
