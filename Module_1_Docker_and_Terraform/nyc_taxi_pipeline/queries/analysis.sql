-- ═══════════════════════════════════════════════════
--  NYC Green Taxi Analysis — PostgreSQL
-- ═══════════════════════════════════════════════════

-- 1. Total records in PostgreSQL
SELECT COUNT(*) AS total_trips
FROM green_taxi_trips;


-- 2. Earliest and latest trip dates in dataset
SELECT
    MIN(lpep_pickup_datetime) AS first_trip,
    MAX(lpep_pickup_datetime) AS last_trip
FROM green_taxi_trips;


-- 3. Daily trip count & revenue
SELECT
    CAST(lpep_pickup_datetime AS DATE)   AS pickup_date,
    COUNT(*)                             AS trips,
    ROUND(SUM(total_amount)::numeric, 2) AS daily_revenue,
    ROUND(AVG(trip_distance)::numeric, 2) AS avg_distance
FROM green_taxi_trips
GROUP BY pickup_date
ORDER BY pickup_date;


-- 4. Top 5 pickup zones with location names joined
SELECT
    z."Zone"    AS pickup_zone,
    z."Borough" AS borough,
    COUNT(*)    AS total_trips
FROM green_taxi_trips t
JOIN zones z ON t."PULocationID" = z."LocationID"
GROUP BY z."Zone", z."Borough"
ORDER BY total_trips DESC
LIMIT 5;


-- 5. Trip distribution by distance category
SELECT
    CASE
        WHEN trip_distance <= 1  THEN '0–1 miles'
        WHEN trip_distance <= 5  THEN '1–5 miles'
        WHEN trip_distance <= 10 THEN '5–10 miles'
        ELSE '10+ miles'
    END AS distance_category,
    COUNT(*)                             AS total_trips,
    ROUND(AVG(total_amount)::numeric, 2) AS avg_fare
FROM green_taxi_trips
WHERE trip_distance > 0
GROUP BY distance_category
ORDER BY avg_fare;


-- 6. Rush hour analysis (Trips per hour of the day)
SELECT
    DATE_PART('hour', lpep_pickup_datetime) AS pickup_hour,
    COUNT(*)                                AS trip_count,
    ROUND(AVG(total_amount)::numeric, 2)    AS avg_amount
FROM green_taxi_trips
GROUP BY pickup_hour
ORDER BY pickup_hour;
