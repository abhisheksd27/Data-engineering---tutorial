# 08 — Homework

## Instructions

Answer the following questions using the Kestra flows and data pipelines built in this module.  
Use Green Taxi data from NYC TLC for the year **2025**.

Data source: `https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-{month:02d}.parquet`

---

## Question 1: Within the execution for Flow `green_taxi_2025`, what is the final status of the `upload_to_s3` task?

Options:
- SUCCESS
- FAILED
- SKIPPED
- RUNNING

**Answer:** Look in Kestra UI → Executions → click the execution → check `upload_to_s3` task status.

---

## Question 2: How many rows were loaded into PostgreSQL for Green Taxi November 2025?

Run in PostgreSQL (psql or pgAdmin):

```sql
SELECT COUNT(*)
FROM green_taxi_trips
WHERE DATE_TRUNC('month', lpep_pickup_datetime) = '2025-11-01';
```

Options:
- ~65,000
- ~80,000
- ~95,000
- ~110,000

---

## Question 3: What is the average trip distance for Green Taxi trips in November 2025?

```sql
SELECT ROUND(AVG(trip_distance)::numeric, 2) AS avg_trip_distance
FROM green_taxi_trips
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01';
```

---

## Question 4: How many S3 objects are in the `raw/` prefix after running the scheduled pipeline for all 12 months of 2025?

After running backfill for Jan–Dec 2025:

```bash
aws s3 ls s3://ny-taxi-data-lake-abhishekshankar-826674/raw/ --region us-east-1 | wc -l
```

Expected: 12 (one file per month)

---

## Question 5: What is the total number of Green Taxi trips across all of 2025 (loaded into PostgreSQL)?

```sql
SELECT COUNT(*) AS total_trips_2025
FROM green_taxi_trips
WHERE lpep_pickup_datetime >= '2025-01-01'
  AND lpep_pickup_datetime < '2026-01-01';
```

---

## Question 6: What is the most common pickup location (PULocationID) for Green Taxi trips in 2025?

```sql
SELECT
  PULocationID,
  COUNT(*) AS trip_count
FROM green_taxi_trips
WHERE lpep_pickup_datetime >= '2025-01-01'
  AND lpep_pickup_datetime < '2026-01-01'
GROUP BY PULocationID
ORDER BY trip_count DESC
LIMIT 5;
```

---

## Bonus: Athena Question

Run this in AWS Athena (workgroup: `ny_taxi_workgroup`, database: `ny_taxi_db`):

```sql
SELECT
  MONTH(lpep_pickup_datetime) AS month,
  COUNT(*) AS trips,
  ROUND(AVG(total_amount), 2) AS avg_fare
FROM green_taxi_trips
WHERE YEAR(lpep_pickup_datetime) = 2025
GROUP BY MONTH(lpep_pickup_datetime)
ORDER BY month;
```

What month had the highest average fare?

---

## Submission Notes

- Screenshot the Kestra execution Gantt chart showing all tasks as SUCCESS
- Include the row count from Question 2
- Include your AWS S3 object count from Question 4
