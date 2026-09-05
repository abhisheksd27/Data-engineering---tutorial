-- ═══════════════════════════════════════════════════
--  Module 1 Homework Queries
-- ═══════════════════════════════════════════════════

-- Q3: Trips in November 2025 with trip_distance <= 1 mile
SELECT COUNT(*) AS short_trips
FROM green_taxi_trips
WHERE
    lpep_pickup_datetime >= '2025-11-01'
    AND lpep_pickup_datetime < '2025-12-01'
    AND trip_distance <= 1;


-- Q4: Pickup day with the longest single trip (excluding >= 100 miles as data errors)
SELECT
    CAST(lpep_pickup_datetime AS DATE) AS pickup_day,
    MAX(trip_distance)                 AS max_distance
FROM green_taxi_trips
WHERE trip_distance < 100
GROUP BY pickup_day
ORDER BY max_distance DESC
LIMIT 1;


-- Q5: Top 3 pickup zones with the biggest total passengers in November 2025
SELECT
    z."Zone",
    SUM(t.passenger_count) AS total_passengers
FROM green_taxi_trips t
JOIN zones z ON t."PULocationID" = z."LocationID"
WHERE
    lpep_pickup_datetime >= '2025-11-01'
    AND lpep_pickup_datetime < '2025-12-01'
GROUP BY z."Zone"
ORDER BY total_passengers DESC NULLS LAST
LIMIT 3;


-- Q6: For passengers picked up in East Harlem North, which drop off zone had the largest tip?
SELECT
    zdo."Zone" AS dropoff_zone,
    MAX(t.tip_amount) AS max_tip
FROM green_taxi_trips t
JOIN zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN zones zdo ON t."DOLocationID" = zdo."LocationID"
WHERE
    zpu."Zone" = 'East Harlem North'
    AND lpep_pickup_datetime >= '2025-11-01'
    AND lpep_pickup_datetime < '2025-12-01'
GROUP BY zdo."Zone"
ORDER BY max_tip DESC
LIMIT 1;
