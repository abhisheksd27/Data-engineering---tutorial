-- ═══════════════════════════════════════════════════════════
-- Amazon Athena Queries (Serverless SQL over S3 Data Lake)
-- Workgroup: ny_taxi_workgroup | Database: ny_taxi_db
-- ═══════════════════════════════════════════════════════════

-- 1. Create External Table for Green Taxi Trips (Parquet)
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
LOCATION 's3://ny-taxi-data-lake-abhishekshankar-826674/raw/';


-- 2. Create External Table for Taxi Zones Lookup (CSV)
CREATE EXTERNAL TABLE IF NOT EXISTS ny_taxi_db.zones (
    LocationID INT,
    Borough STRING,
    Zone STRING,
    service_zone STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
   "separatorChar" = ",",
   "quoteChar"     = "\""
)
LOCATION 's3://ny-taxi-data-lake-abhishekshankar-826674/lookup/'
TBLPROPERTIES ('skip.header.line.count'='1');


-- 3. Query total trips directly from S3
SELECT COUNT(*) AS total_trips
FROM ny_taxi_db.green_taxi_trips;


-- 4. Daily trips and revenue directly over S3 Parquet files
SELECT
    DATE_TRUNC('day', lpep_pickup_datetime) AS pickup_day,
    COUNT(*)                                AS total_trips,
    ROUND(SUM(total_amount), 2)             AS daily_revenue
FROM ny_taxi_db.green_taxi_trips
GROUP BY 1
ORDER BY 1;


-- 5. Top 5 pickup zones joined with zones table directly in Athena
SELECT
    z.Zone,
    z.Borough,
    COUNT(*) AS total_trips
FROM ny_taxi_db.green_taxi_trips t
JOIN ny_taxi_db.zones z ON t.PULocationID = z.LocationID
GROUP BY z.Zone, z.Borough
ORDER BY total_trips DESC
LIMIT 5;