import pandas as pd
from sqlalchemy import create_engine

df = pd.read_parquet('green_tripdata_2025-11.parquet')

print(df.shape)
print(df.dtypes)
print(df.head())
print(df.isnull().sum())

engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')
print(pd.io.sql.get_schema(df, name='yellow_taxi_trips', con=engine))# Parse datetime columns properly
df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)