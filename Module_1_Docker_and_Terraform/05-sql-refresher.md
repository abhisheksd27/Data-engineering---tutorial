# 🗃️ Topic 5: SQL Refresher on NYC Taxi Data

> **GitHub**: [10-sql-refresher.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/01-docker-terraform/docker-sql/10-sql-refresher.md)  
> **Video**: [SQL Refresher Video](https://www.youtube.com/watch?v=QEcps_iskgg)

---

## 🔗 Prerequisites

- PostgreSQL container running
- `yellow_taxi_trips` table loaded (~1M rows)
- `zones` table loaded (265 rows)
- pgAdmin at http://localhost:8080

---

## 🧠 The Two Tables We'll Use

### yellow_taxi_trips (main fact table)

```
VendorID | tpep_pickup_datetime  | tpep_dropoff_datetime | trip_distance | PULocationID | DOLocationID | total_amount
---------|----------------------|----------------------|---------------|--------------|--------------|-------------
1        | 2021-01-01 00:30:10  | 2021-01-01 00:36:12  | 1.2           | 238          | 79           | 6.30
2        | 2021-01-01 00:15:56  | 2021-01-01 00:19:52  | 0.5           | 193          | 193          | 4.00
```

### zones (lookup/dimension table)

```
LocationID | Borough   | Zone                  | service_zone
-----------|------------|----------------------|-------------
1          | EWR        | Newark Airport        | EWR
79         | Manhattan  | East Village          | Yellow Zone
238        | Manhattan  | Upper West Side South | Yellow Zone
```

---

## 📊 1. Basic Queries

### Count all trips

```sql
SELECT COUNT(*) FROM yellow_taxi_trips;
-- 1,369,765
```

### View first few rows

```sql
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount
FROM yellow_taxi_trips
LIMIT 5;
```

### Filter trips with no passengers

```sql
SELECT
    tpep_pickup_datetime,
    passenger_count
FROM yellow_taxi_trips
WHERE passenger_count = 0;
```

---

## 🔗 2. JOIN Queries

### Implicit INNER JOIN (old style)

Join trips with zones to get pickup and dropoff location names:

```sql
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' | ', zdo."Zone") AS "dropoff_loc"
FROM
    yellow_taxi_trips t,
    zones zpu,
    zones zdo
WHERE
    t."PULocationID" = zpu."LocationID"
    AND t."DOLocationID" = zdo."LocationID"
LIMIT 100;
```

**Output:**
```
tpep_pickup_datetime | total_amount | pickup_loc                        | dropoff_loc
---------------------|--------------|-----------------------------------|------------------
2021-01-01 00:30:10  | 6.30         | Manhattan | Upper West Side South | Manhattan | East Village
```

### Explicit INNER JOIN (recommended style)

```sql
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' / ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' / ', zdo."Zone") AS "dropoff_loc"
FROM yellow_taxi_trips t
JOIN zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN zones zdo ON t."DOLocationID" = zdo."LocationID"
LIMIT 100;
```

### LEFT JOIN (include trips even if zone is missing)

```sql
SELECT
    tpep_pickup_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' / ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' / ', zdo."Zone") AS "dropoff_loc"
FROM yellow_taxi_trips t
LEFT JOIN zones zpu ON t."PULocationID" = zpu."LocationID"
LEFT JOIN zones zdo ON t."DOLocationID" = zdo."LocationID"
WHERE zpu."Zone" IS NULL OR zdo."Zone" IS NULL
LIMIT 100;
```

> Use LEFT JOIN when you want **all rows from the left table**, even if no match exists in the right table.

---

## 🔍 3. Finding NULL Locations

```sql
-- Find trips where pickup location is not in zones table
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    "PULocationID",
    "DOLocationID"
FROM yellow_taxi_trips t
WHERE "PULocationID" NOT IN (SELECT "LocationID" FROM zones)
LIMIT 100;
```

---

## 📅 4. Grouping and Aggregation

### Count trips per day

```sql
SELECT
    CAST(tpep_pickup_datetime AS DATE) AS "day",
    COUNT(1) AS trip_count
FROM yellow_taxi_trips
GROUP BY "day"
ORDER BY "day" ASC;
```

### Max trips in a single day

```sql
SELECT
    CAST(tpep_pickup_datetime AS DATE) AS "day",
    COUNT(1) AS trip_count
FROM yellow_taxi_trips
GROUP BY "day"
ORDER BY trip_count DESC
LIMIT 5;
```

### Daily revenue

```sql
SELECT
    CAST(tpep_pickup_datetime AS DATE) AS "day",
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_fare,
    MAX(total_amount) AS max_fare
FROM yellow_taxi_trips
GROUP BY "day"
ORDER BY total_revenue DESC;
```

---

## 🏆 5. GROUP BY with JOINs

Find the most popular pickup zones:

```sql
SELECT
    CONCAT(zpu."Borough", ' / ', zpu."Zone") AS "pickup_loc",
    COUNT(1) AS trip_count,
    SUM(total_amount) AS total_revenue
FROM yellow_taxi_trips t
JOIN zones zpu ON t."PULocationID" = zpu."LocationID"
GROUP BY zpu."Borough", zpu."Zone"
ORDER BY trip_count DESC
LIMIT 10;
```

---

## 🕐 6. Date/Time Operations

### Extract parts of a datetime

```sql
SELECT
    tpep_pickup_datetime,
    DATE_PART('hour', tpep_pickup_datetime) AS pickup_hour,
    DATE_PART('dow', tpep_pickup_datetime) AS day_of_week, -- 0=Sunday
    EXTRACT(MONTH FROM tpep_pickup_datetime) AS month
FROM yellow_taxi_trips
LIMIT 10;
```

### Trips per hour of day

```sql
SELECT
    DATE_PART('hour', tpep_pickup_datetime) AS pickup_hour,
    COUNT(*) AS trips
FROM yellow_taxi_trips
GROUP BY pickup_hour
ORDER BY pickup_hour;
```

---

## 📏 7. Filtering with WHERE

### Short trips (≤ 1 mile) — Homework Q3 type

```sql
SELECT COUNT(*)
FROM yellow_taxi_trips
WHERE
    lpep_pickup_datetime >= '2025-11-01'
    AND lpep_pickup_datetime < '2025-12-01'
    AND trip_distance <= 1;
```

### Longest trip per day — Homework Q4 type

```sql
SELECT
    CAST(lpep_pickup_datetime AS DATE) AS pickup_day,
    MAX(trip_distance) AS max_distance
FROM yellow_taxi_trips
WHERE trip_distance < 100  -- exclude data errors
GROUP BY pickup_day
ORDER BY max_distance DESC
LIMIT 5;
```

---

## 📊 SQL Concepts Summary

| Concept | SQL Keyword | Purpose |
|---------|-------------|---------|
| Select specific columns | `SELECT col1, col2` | Choose what to show |
| Filter rows | `WHERE condition` | Reduce rows |
| Join tables | `JOIN ... ON` | Combine related data |
| Aggregate | `COUNT, SUM, AVG, MAX` | Summarize |
| Group | `GROUP BY` | Aggregate per category |
| Sort | `ORDER BY col DESC` | Order results |
| Limit | `LIMIT n` | Take only first n rows |
| Date extract | `DATE_PART`, `CAST AS DATE` | Work with timestamps |
| String concat | `CONCAT(a, ' ', b)` | Combine strings |
| Null check | `IS NULL`, `IS NOT NULL` | Find missing values |

---

## 🔗 How SQL Connects to the Data Pipeline

```
Raw Data (CSV/Parquet)
    ↓ Python ingestion
PostgreSQL (ny_taxi database)
    ↓ SQL queries
Analytics & Insights
    ↓ Tableau / Metabase / Looker / dbt (Module 4)
Business Dashboards
```

The SQL skills you practice here are the SAME skills used in:
- **Module 3**: BigQuery (cloud SQL)
- **Module 4**: dbt (SQL-based transformations)
- **Final Project**: Answering business questions from your data

---

*Previous: [Topic 4 - Docker Compose](04-docker-compose.md) | Next: [Topic 6 - GCP Overview →](06-gcp-overview.md)*
