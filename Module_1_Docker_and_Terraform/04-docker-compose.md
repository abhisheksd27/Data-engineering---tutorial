# 🐙 Topic 4: Docker Compose

> **GitHub**: [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql)  
> **Video**: [Docker + Postgres Workshop](https://www.youtube.com/watch?v=lP8xXebHmuE)

---

## 🤔 Why Docker Compose?

So far, we've been running containers one by one with long `docker run` commands. That becomes messy when you have multiple containers that need to work together.

**Docker Compose** solves this by letting you define all your containers in a single **YAML file**, then start them all with one command.

### Before (without Docker Compose)

```bash
# 3 separate commands, lots of flags to remember
docker network create pg-network

docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=pg-network \
  --name pg-database \
  postgres:17

docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -p 8080:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4
```

### After (with Docker Compose)

Just run: `docker-compose up`

---

## 📄 docker-compose.yaml Syntax

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
      - '5432:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

---

## 🔑 Key Concepts in the YAML

### Services
Each `service` is a container:
- `db` — the PostgreSQL database
- `pgadmin` — the admin UI

### Environment Variables
Pass config without hardcoding in the container:
```yaml
environment:
  POSTGRES_USER: 'postgres'
```

### Ports
```yaml
ports:
  - '5432:5432'  # host:container
```
Maps container port to your machine port.

### Volumes
```yaml
volumes:
  - vol-pgdata:/var/lib/postgresql/data
```
Named volumes (managed by Docker) for persistent storage.

> ⚠️ **Homework Question**: In the above `docker-compose.yaml`, what host and port should pgAdmin use to connect to Postgres?
> - Answer: **`postgres:5432`** (the container name is `postgres`, internal port is 5432)
> - NOT `localhost:5432` — containers communicate by service/container name inside Docker network!

---

## 🚀 Docker Compose Commands

```bash
# Start all services (in the foreground)
docker-compose up

# Start all services in the background (detached)
docker-compose up -d

# Stop all services
docker-compose down

# Stop and remove volumes (wipes data!)
docker-compose down --volumes

# View logs
docker-compose logs

# View logs for a specific service
docker-compose logs db

# Rebuild images before starting
docker-compose up --build

# List running services
docker-compose ps
```

---

## 🌐 Networking in Docker Compose

Docker Compose **automatically creates a network** for all services defined in the same file. You don't need to manually create a network!

```
docker-compose network (auto-created: "project_default")
     ├── db (container: postgres, hostname: db)
     └── pgadmin (container: pgadmin, hostname: pgadmin)
```

So pgAdmin connects to Postgres using:
- **Host**: `db` (service name) or `postgres` (container name)
- **Port**: `5432` (internal port, NOT the host-mapped port)

---

## 🔄 Docker Compose Lifecycle

```
docker-compose up
     ↓
1. Creates network
2. Creates named volumes (if not exist)
3. Pulls images (if not local)
4. Starts containers in order
5. All containers ready ✅

docker-compose down
     ↓
1. Stops containers
2. Removes containers
3. Removes network
4. Volumes remain (data safe)

docker-compose down -v
     ↓
Same as above + removes volumes (data deleted!)
```

---

## 📊 Visual: How Compose Ties Everything Together

```
Your Machine (macOS/Linux/Windows)
│
├── docker-compose.yaml
│
├── Port 5432 ──────────────────────────────→ [postgres container]
│                                                   ├── ny_taxi database
│                                                   └── vol-pgdata (volume)
│
├── Port 8080 ──────────────────────────────→ [pgadmin container]
│                                                   └── vol-pgadmin_data (volume)
│
└── Docker Network (project_default)
         ├── postgres ←→ pgadmin (can talk by service name)
         └── taxi_ingest container (when running ingestion)
```

---

## 🧪 Extended Example: Adding the Ingestion Container

You can add a one-time ingestion job to the compose file:

```yaml
services:
  db:
    image: postgres:17-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: 'root'
      POSTGRES_PASSWORD: 'root'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5432:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    image: dpage/pgadmin4
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: "admin@admin.com"
      PGADMIN_DEFAULT_PASSWORD: "root"
    ports:
      - "8080:80"
    depends_on:
      - db

  ingest:
    build: .                        # Build from local Dockerfile
    container_name: taxi_ingest
    command: >
      --user=root
      --password=root
      --host=db
      --port=5432
      --db=ny_taxi
      --table_name=yellow_taxi_trips
      --url=https://your-data-url/file.csv.gz
    depends_on:
      - db

volumes:
  vol-pgdata:
  vol-pgadmin_data:
```

---

## ✅ Summary

| Feature | Without Compose | With Compose |
|---------|----------------|--------------|
| Starting containers | Multiple `docker run` commands | `docker-compose up` |
| Networking | Manual `docker network create` | Automatic |
| Configuration | Flags on command line | YAML file (version controlled) |
| Stopping | Multiple `docker stop` | `docker-compose down` |
| Repeatable setup | Hard to share | Just share the YAML file |

---

*Previous: [Topic 3 - Data Ingestion](03-data-ingestion-python.md) | Next: [Topic 5 - SQL Refresher →](05-sql-refresher.md)*
