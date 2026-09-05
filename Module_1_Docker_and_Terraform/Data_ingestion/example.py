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

