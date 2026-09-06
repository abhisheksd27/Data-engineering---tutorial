-- ============================================================
-- athena_queries.sql
-- SQL queries to run against S3 data via AWS Athena
-- Database: ny_taxi_db
-- Workgroup: ny_taxi_workgroup
-- S3 Bucket: ny-taxi-data-lake-abhishekshankar-826674
-- ============================================================

-- ─── Step 0: Create external table (run once) ────────────────────────────
CREATE EXTERNAL TABLE IF NOT EXISTS ny_taxi_db.green_taxi_trips (
    VendorID            INT,
    lpep_pickup_datetime    TIMESTAMP,
    lpep_dropoff_datetime   TIMESTAMP,
    store_and_fwd_flag  STRING,
    RatecodeID          INT,
    PULocationID        INT,
    DOLocationID        INT,
    passenger_count     INT,
    trip_distance       DOUBLE,
    fare_amount         DOUBLE,
    extra               DOUBLE,
    mta_tax             DOUBLE,
    tip_amount          DOUBLE,
    tolls_amount        DOUBLE,
    improvement_surcharge DOUBLE,
    total_amount        DOUBLE,
    payment_type        INT,
    trip_type           INT,
    congestion_surcharge DOUBLE
)
STORED AS PARQUET
LOCATION 's3://ny-taxi-data-lake-abhishekshankar-826674/raw/'
TBLPROPERTIES ("parquet.compression"="SNAPPY");

-- ─── Query 1: Total trip count ────────────────────────────────────────────
SELECT COUNT(*) AS total_trips
FROM ny_taxi_db.green_taxi_trips;

-- ─── Query 2: Monthly trip counts and revenue ────────────────────────────
SELECT
    YEAR(lpep_pickup_datetime)  AS year,
    MONTH(lpep_pickup_datetime) AS month,
    COUNT(*)                    AS trips,
    ROUND(AVG(total_amount), 2) AS avg_fare,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM ny_taxi_db.green_taxi_trips
GROUP BY
    YEAR(lpep_pickup_datetime),
    MONTH(lpep_pickup_datetime)
ORDER BY year, month;

-- ─── Query 3: Top 10 pickup zones ────────────────────────────────────────
SELECT
    PULocationID,
    COUNT(*) AS pickups
FROM ny_taxi_db.green_taxi_trips
GROUP BY PULocationID
ORDER BY pickups DESC
LIMIT 10;

-- ─── Query 4: Average trip distance by month ─────────────────────────────
SELECT
    MONTH(lpep_pickup_datetime) AS month,
    ROUND(AVG(trip_distance), 2) AS avg_distance_miles
FROM ny_taxi_db.green_taxi_trips
WHERE YEAR(lpep_pickup_datetime) = 2025
GROUP BY MONTH(lpep_pickup_datetime)
ORDER BY month;

-- ─── Query 5: Revenue breakdown by payment type ──────────────────────────
SELECT
    payment_type,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount), 2) AS revenue
FROM ny_taxi_db.green_taxi_trips
GROUP BY payment_type
ORDER BY revenue DESC;
