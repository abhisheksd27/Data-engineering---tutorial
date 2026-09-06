# 03 — Installing Kestra with Docker Compose

## Architecture

We run two services in Docker:

```
┌─────────────────────────────────────┐
│           Docker Compose            │
│                                     │
│  ┌──────────────┐  ┌─────────────┐  │
│  │    Kestra    │  │  PostgreSQL │  │
│  │  (port 8080) │──│  (port 5432)│  │
│  │  UI + Engine │  │  Kestra DB  │  │
│  └──────────────┘  └─────────────┘  │
│                                     │
└─────────────────────────────────────┘
         ↓ Kestra executes flows ↓
    ┌────────────────────────────┐
    │   Your Python Scripts /   │
    │   AWS S3 / PostgreSQL     │
    └────────────────────────────┘
```

**Note:** Kestra uses PostgreSQL as its **internal metadata store** (not your taxi data DB).  
You can optionally add a separate PostgreSQL container for the taxi data (reusing Module 1 setup).

---

## `docker-compose.yaml` (See project file for full code)

The compose file has these services:

| Service | Image | Port | Purpose |
|---|---|---|---|
| `kestra` | `kestra/kestra:latest` | `8080` | Kestra orchestration engine + UI |
| `postgres-kestra` | `postgres:15` | `5433` | Kestra's internal metadata database |
| `postgres-taxi` | `postgres:15` | `5432` | NYC taxi data (same as Module 1) |

---

## Step-by-Step Setup

### Step 1: Clone or enter the project folder

```bash
cd "Data engineering - tutorial/Module_2_Workflow_Orchestration/nyc_taxi_pipeline_m2"
```

### Step 2: Set up your `.env` file

The `.env` file holds credentials for both PostgreSQL databases and AWS.  
**Never commit this to git.**

```
# Kestra internal DB
KESTRA_DB_USER=kestra
KESTRA_DB_PASSWORD=kestra_password
KESTRA_DB_NAME=kestra

# NYC Taxi PostgreSQL DB (same as Module 1)
POSTGRES_USER=root
POSTGRES_PASSWORD=root
POSTGRES_DB=ny_taxi

# AWS (for flows that upload to S3)
AWS_ACCESS_KEY_ID=your_key_here
AWS_SECRET_ACCESS_KEY=your_secret_here
AWS_DEFAULT_REGION=us-east-1
S3_BUCKET=ny-taxi-data-lake-abhishekshankar-826674
```

### Step 3: Start Kestra

```bash
docker compose up -d
```

Wait ~30 seconds for Kestra to fully start up.

### Step 4: Verify Kestra is running

Open browser: http://localhost:8080

You should see the Kestra dashboard.

### Step 5: Check running containers

```bash
docker compose ps
```

Expected output:
```
NAME               STATUS    PORTS
kestra             Up        0.0.0.0:8080->8080/tcp
postgres-kestra    Up        0.0.0.0:5433->5432/tcp
postgres-taxi      Up        0.0.0.0:5432->5432/tcp
```

---

## Adding Flows to Kestra

### Option A: Kestra UI (copy-paste YAML)
1. Go to http://localhost:8080
2. Click **Flows** → **Create**
3. Paste your YAML flow
4. Click **Save**
5. Click **Execute** to run manually

### Option B: Kestra API (programmatic import)

```bash
# Import a flow via API
curl -X POST http://localhost:8080/api/v1/flows/import \
  -F fileUpload=@flows/01_hello_world.yaml

# If you set up authentication (username/password), use:
curl -X POST -u 'admin@kestra.io:Admin1234!' \
  http://localhost:8080/api/v1/flows/import \
  -F fileUpload=@flows/01_hello_world.yaml
```

### Import all flows at once

```bash
for f in flows/*.yaml; do
  curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@$f
done
```

---

## Stopping Kestra

```bash
docker compose down           # Stop containers (keep data)
docker compose down -v        # Stop + delete all volumes (fresh start)
```

---

## Kestra Storage

Kestra stores file outputs (downloaded parquet files, script outputs) in its **internal storage**.  
By default this is local filesystem inside the container.

You can configure Kestra to use **S3 as internal storage** for production:

```yaml
# In kestra configuration (advanced)
kestra:
  storage:
    type: s3
    s3:
      bucket: kestra-internal-storage-bucket
      region: us-east-1
```

For this module, we use the default local storage.

---

## Port Conflict Warning

**Problem:** pgAdmin from Module 1 sometimes runs on port 8080.

**Check:**
```bash
lsof -i :8080
```

**Fix:** Change pgAdmin port to 8090 in Module 1 docker-compose or stop it first:

```bash
docker stop pgadmin
```

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `localhost:8080` not responding | Kestra still starting up | Wait 30s, retry |
| `port already in use: 8080` | pgAdmin or another service on 8080 | Stop conflicting container |
| `postgres-kestra` container exits | Wrong credentials in `.env` | Check `KESTRA_DB_*` env vars |
| Flows not appearing | Namespace mismatch | Check `namespace` in YAML matches expected |
| Python task fails with `ModuleNotFoundError` | Package not installed in Kestra's Python env | Add `beforeCommands: pip install <pkg>` to task |
