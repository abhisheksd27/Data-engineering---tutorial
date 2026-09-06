-- ============================================================
-- postgres_analysis.sql
-- Validation and analysis queries for data loaded by Kestra
-- Run against: ny_taxi PostgreSQL DB (localhost:5432)
-- ============================================================

-- 1. Check how many rows are in the table
SELECT COUNT(*) AS total_rows
FROM green_taxi_trips;

-- 2. Check date range of data loaded
SELECT
    MIN(lpep_pickup_datetime) AS earliest_trip,
    MAX(lpep_pickup_datetime) AS latest_trip
FROM green_taxi_trips;

-- 3. Check row count by month (useful after backfill)
SELECT
    year,
    month,
    COUNT(*) AS trip_count
FROM green_taxi_trips
GROUP BY year, month
ORDER BY year, month;

-- 4. Average fare and distance by month
SELECT
    year,
    month,
    ROUND(AVG(total_amount)::numeric, 2)   AS avg_fare,
    ROUND(AVG(trip_distance)::numeric, 2)  AS avg_distance,
    COUNT(*) AS trips
FROM green_taxi_trips
GROUP BY year, month
ORDER BY year, month;

-- 5. Top 10 pickup locations
SELECT
    pulocationid,
    COUNT(*) AS pickups
FROM green_taxi_trips
GROUP BY pulocationid
ORDER BY pickups DESC
LIMIT 10;

-- 6. Trip count by vendor
SELECT
    vendorid,
    COUNT(*) AS trips,
    ROUND(AVG(total_amount)::numeric, 2) AS avg_fare
FROM green_taxi_trips
GROUP BY vendorid
ORDER BY trips DESC;

-- 7. Distribution of passenger count
SELECT
    passenger_count,
    COUNT(*) AS trips,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS pct
FROM green_taxi_trips
GROUP BY passenger_count
ORDER BY passenger_count;

-- 8. Revenue by payment type
SELECT
    payment_type,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue
FROM green_taxi_trips
GROUP BY payment_type
ORDER BY total_revenue DESC;
