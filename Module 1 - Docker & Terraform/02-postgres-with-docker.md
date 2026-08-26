# 🐘 Topic 2: Running PostgreSQL with Docker

> **GitHub**: [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql)  
> **Video**: [Docker + Postgres Workshop](https://www.youtube.com/watch?v=lP8xXebHmuE)

---

## 🤔 Why PostgreSQL?

In data engineering, we need a place to **store and query structured data**. PostgreSQL (Postgres) is:
- A powerful **open-source relational database**
- Supports SQL (Structured Query Language)
- Used extensively for data warehousing and analytics
- Free, battle-tested, and widely supported

In Module 1, we use Postgres as our **local data store** before moving to cloud solutions (BigQuery in Module 3).

---

## 🚀 Running PostgreSQL in Docker

Instead of installing Postgres directly on your machine, we run it as a Docker container. This gives us:
- Easy setup (one command!)
- Clean environment
- Easy to reset/recreate

### Step 1: Create a network (so containers can talk)

```bash
docker network create pg-network
```

### Step 2: Run the PostgreSQL container

```bash
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=pg-network \
  --name pg-database \
  postgres:17
```

**Breaking down the flags:**

| Flag | Purpose |
|------|---------|
| `-e POSTGRES_USER="root"` | Set the database username |
| `-e POSTGRES_PASSWORD="root"` | Set the database password |
| `-e POSTGRES_DB="ny_taxi"` | Create a database named `ny_taxi` |
| `-v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data` | Mount a local folder for **persistent storage** |
| `-p 5432:5432` | Expose port 5432 (Postgres default) |
| `--network=pg-network` | Join our custom network |
| `--name pg-database` | Name the container (for easy reference) |
| `postgres:17` | Use official Postgres 17 image |

> ⚠️ **Important**: Without `-v`, all your data disappears when the container stops!

---

## 🖥️ Running pgAdmin (Database GUI)

pgAdmin is a web-based interface for managing PostgreSQL databases.

```bash
docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -p 8080:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4
```

Then open your browser: **http://localhost:8080**

Login with:
- Email: `admin@admin.com`
- Password: `root`

### Connect pgAdmin to your Postgres container

In pgAdmin, right-click "Servers" → Create → Server:
- **Name**: Local Docker Postgres
- **Host**: `pg-database` (the container name!)
- **Port**: `5432`
- **Username**: `root`
- **Password**: `root`

> 💡 **Key concept**: Because both containers are on `pg-network`, pgAdmin can reach Postgres by its **container name** (`pg-database`), not `localhost`!

---

## 🔌 Connecting to PostgreSQL with pgcli

`pgcli` is a command-line tool to interact with Postgres. Install it:

```bash
pip install pgcli
```

Connect to your database:

```bash
pgcli -h localhost -p 5432 -u root -d ny_taxi
```

| Flag | Meaning |
|------|---------|
| `-h localhost` | Host (your local machine) |
| `-p 5432` | Port |
| `-u root` | Username |
| `-d ny_taxi` | Database name |

Once connected, try some commands:

```sql
-- List all tables
\dt

-- Describe a table's schema
\d yellow_taxi_trips

-- Query data
SELECT COUNT(*) FROM yellow_taxi_trips;
```

---

## 🏗️ Understanding the Database Schema

When we load the NYC Taxi data, the main table `yellow_taxi_trips` has these key columns:

| Column | Type | Description |
|--------|------|-------------|
| `VendorID` | INTEGER | Taxi company ID |
| `tpep_pickup_datetime` | TIMESTAMP | Trip start time |
| `tpep_dropoff_datetime` | TIMESTAMP | Trip end time |
| `passenger_count` | FLOAT | Number of passengers |
| `trip_distance` | FLOAT | Distance in miles |
| `PULocationID` | INTEGER | Pickup zone ID |
| `DOLocationID` | INTEGER | Dropoff zone ID |
| `fare_amount` | FLOAT | Base fare |
| `total_amount` | FLOAT | Total charge |

And a separate lookup table `zones`:

| Column | Type | Description |
|--------|------|-------------|
| `LocationID` | INTEGER | Zone identifier |
| `Borough` | TEXT | NYC borough name |
| `Zone` | TEXT | Specific zone name |
| `service_zone` | TEXT | Type of service zone |

---

## 🔄 Data Flow Diagram

```
NYC Taxi Website (CSV/Parquet files)
         ↓
     Python Script
  (pandas + sqlalchemy)
         ↓
  PostgreSQL Container
  (port 5432, Docker)
         ↓
    pgAdmin GUI
  (port 8080, Docker)
```

---

## 🧪 Verifying Your Setup

Run these SQL queries to verify everything is working:

```sql
-- Check if data is loaded
SELECT COUNT(*) FROM yellow_taxi_trips;
-- Expected: ~1,000,000+ rows

-- Check zones table
SELECT COUNT(*) FROM zones;
-- Expected: 265 rows

-- Quick sanity check
SELECT * FROM yellow_taxi_trips LIMIT 5;
```

---

## ⚠️ Common Issues & Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| `Connection refused` | Postgres not running | Run `docker ps` and check container is up |
| `FATAL: database does not exist` | Wrong DB name | Use `-d ny_taxi` not `-d postgres` |
| Data disappears on restart | No volume mount | Always use `-v` flag |
| pgAdmin can't connect | Wrong hostname | Use container name, not `localhost` |
| Port already in use | Another service on 5432 | Change host port: `-p 5433:5432` |

---

## 📌 Summary

```
✅ PostgreSQL runs as a Docker container
✅ Data persists on your filesystem via volume mount
✅ pgAdmin gives you a GUI to explore the database
✅ Both containers communicate via a Docker network
✅ pgcli lets you run SQL queries from the terminal
```

---

*Previous: [Topic 1 - Docker Fundamentals](01-docker-fundamentals.md) | Next: [Topic 3 - Data Ingestion with Python →](03-data-ingestion-python.md)*
