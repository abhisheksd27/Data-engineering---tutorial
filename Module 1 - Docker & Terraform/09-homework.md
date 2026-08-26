# 📝 Module 1 Homework: Docker & SQL

> **Official Homework**: [homework.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/01-docker-terraform/homework.md)

---

## 📋 Setup

Before answering the questions, download the dataset:

```bash
# Green Taxi trips for November 2025
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet

# Zones lookup
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

Load both into PostgreSQL using the ingestion script from Topic 3.

---

## ❓ Question 1: Understanding Docker Images

**Task**: Run docker with the `python:3.13` image and check pip version.

```bash
docker run -it python:3.13 bash
pip --version
```

**What to look for**: The version string of pip inside the container.

Options:
- 25.3
- 24.3.1
- 24.2.1
- 23.3.1

**Answer**: `25.3`

**Explanation**:
The `python:3.13` image ships with a specific version of pip. When you run the container with `bash` as the entrypoint (overriding the default CMD), you get an interactive shell inside the container.

```bash
# Step by step:
docker run -it python:3.13 bash
# -i = interactive, keep stdin open
# -t = allocate a terminal
# python:3.13 = use this image
# bash = the command to run (overrides default)

# Inside the container:
root@abc123:/# pip --version
pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
```

---

## ❓ Question 2: Docker Networking and Docker Compose

**Task**: Given this `docker-compose.yaml`, what hostname and port should pgAdmin use to connect to Postgres?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'    # ← Notice: host port 5433, container port 5432

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    ports:
      - "8080:80"
```

Options:
- postgres:5433
- localhost:5432
- db:5433
- **postgres:5432** ✅
- db:5432 ✅

**Answer**: `db:5432` OR `postgres:5432`

**Explanation**:

This is a crucial networking concept!

```
Host Machine
   Port 5433 ──────────────────────────────┐
                                           ↓
                              [postgres container]
                              Internal port: 5432
                              Container name: postgres
                              Service name: db

pgAdmin (inside Docker network) connects via:
   hostname: db (service name) OR postgres (container name)
   port: 5432 (internal port, NOT 5433!)

YOU connect from browser via:
   localhost:5433 (host port mapping)
```

**Key rule**: Containers on the same Docker network communicate via **internal ports** and **service/container names** — NOT host port mappings!

---

## ❓ Question 3: Counting Short Trips

**Task**: For November 2025 trips, how many had a `trip_distance` ≤ 1 mile?

**SQL Solution**:

```sql
SELECT COUNT(*) AS short_trips
FROM green_taxi_trips
WHERE
    lpep_pickup_datetime >= '2025-11-01'
    AND lpep_pickup_datetime < '2025-12-01'
    AND trip_distance <= 1;
```

Options:
- 7,853
- **8,007** ✅ (approximate — use your actual result)
- 8,254
- 8,421

**Explanation**:
- `lpep_pickup_datetime >= '2025-11-01'` — trips FROM November 1st
- `lpep_pickup_datetime < '2025-12-01'` — trips BEFORE December (exclusive upper bound)
- `trip_distance <= 1` — 1 mile or less

> Note: The exact answer depends on the actual dataset. Run the query and report what you get.

---

## ❓ Question 4: Longest Trip Per Day

**Task**: Which pickup day had the longest trip distance? Exclude trips ≥ 100 miles (data errors).

**SQL Solution**:

```sql
SELECT
    CAST(lpep_pickup_datetime AS DATE) AS pickup_day,
    MAX(trip_distance) AS max_distance
FROM green_taxi_trips
WHERE trip_distance < 100
GROUP BY pickup_day
ORDER BY max_distance DESC
LIMIT 1;
```

Options:
- 2025-11-14
- **2025-11-20** ✅ (approximate — check your result)
- 2025-11-23
- 2025-11-25

**Explanation**:
- `WHERE trip_distance < 100` — filters out obvious data errors (100+ mile taxi trips)
- `GROUP BY pickup_day` — one row per calendar day
- `MAX(trip_distance)` — longest trip in that day
- `ORDER BY max_distance DESC LIMIT 1` — take the day with the longest trip

---

## 🏗️ Bonus: Additional Analysis Queries

These aren't in the official homework, but practice them!

### Which zone had the most pickups?

```sql
SELECT
    z."Zone",
    z."Borough",
    COUNT(*) AS trips
FROM green_taxi_trips t
JOIN zones z ON t."PULocationID" = z."LocationID"
WHERE
    lpep_pickup_datetime >= '2025-11-01'
    AND lpep_pickup_datetime < '2025-12-01'
GROUP BY z."Zone", z."Borough"
ORDER BY trips DESC
LIMIT 3;
```

### Total revenue by borough

```sql
SELECT
    z."Borough",
    COUNT(*) AS trips,
    ROUND(SUM(t.total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(t.total_amount)::numeric, 2) AS avg_fare
FROM green_taxi_trips t
JOIN zones z ON t."PULocationID" = z."LocationID"
WHERE
    lpep_pickup_datetime >= '2025-11-01'
    AND lpep_pickup_datetime < '2025-12-01'
GROUP BY z."Borough"
ORDER BY total_revenue DESC;
```

---

## 📤 Submitting Your Homework

According to the course instructions:
1. Create a **public GitHub repository** for your homework solution
2. Include:
   - Your SQL queries in a README or `.sql` file
   - Links to your code
3. Submit your answers on the [course platform](https://courses.datatalks.club/)

**What to include in your repo:**

```
homework/module1/
├── README.md          ← Your answers with explanations
├── homework.sql       ← All SQL queries
├── docker-compose.yaml
├── Dockerfile
└── ingest_data.py
```

**README template:**

```markdown
# Module 1 Homework Answers

## Q1: pip version in python:3.13
Answer: 25.3
Command: `docker run -it python:3.13 bash` then `pip --version`

## Q2: pgAdmin connection hostname:port
Answer: db:5432 or postgres:5432
Explanation: In Docker network, containers communicate by service/container name
on internal ports (not host-mapped ports).

## Q3: Short trips (≤ 1 mile) in November 2025
Answer: [your count]
SQL: [paste your query]

## Q4: Day with longest trip
Answer: [your date]
SQL: [paste your query]
```

---

## 🔗 Useful Links for the Homework

| Resource | Link |
|----------|------|
| Official Homework | [homework.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/01-docker-terraform/homework.md) |
| Green Taxi Data | [NYC TLC Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) |
| Zones CSV | [taxi_zone_lookup.csv](https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv) |
| Course Platform | [courses.datatalks.club](https://courses.datatalks.club/) |
| Slack Help | [#course-data-engineering](https://app.slack.com/client/T01ATQK62F8/C01FABYF2RG) |

---

*Previous: [Module 1 Project](08-project.md) | Next Module: [Module 2 - Workflow Orchestration](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/02-workflow-orchestration)*
