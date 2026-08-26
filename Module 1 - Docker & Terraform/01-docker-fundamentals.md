# 🐳 Topic 1: Docker Fundamentals

> **GitHub**: [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql)  
> **Video**: [Docker + Postgres Workshop](https://www.youtube.com/watch?v=lP8xXebHmuE)

---

## 🤔 What is Docker?

Docker is a platform that lets you **package an application and all its dependencies** into a single, portable unit called a **container**. 

Think of it like this:
- 📦 **Without Docker**: "It works on my machine!" — dependencies differ between computers
- ✅ **With Docker**: The same container runs identically on any machine (your laptop, a server, the cloud)

### Real-world analogy
A **Docker container** is like a shipping container 🚢:
- It contains everything needed (code, libraries, config)
- It runs identically anywhere (ship, truck, warehouse)
- You can stack/run multiple containers at once

---

## 🧱 Core Concepts

### 1. Docker Image
A **blueprint/template** — a read-only snapshot of a filesystem with everything pre-installed.

```
Image = OS layer + installed software + your code
```

| Command | What it does |
|---------|-------------|
| `docker pull python:3.11` | Download Python 3.11 image |
| `docker images` | List all local images |
| `docker rmi image_name` | Remove an image |

### 2. Docker Container
A **running instance** of an image. You can run many containers from one image.

```
Image → Container (running process)
        Container (another running process)
        Container (yet another)
```

| Command | What it does |
|---------|-------------|
| `docker run python:3.11` | Start a container from image |
| `docker ps` | List running containers |
| `docker ps -a` | List all containers (including stopped) |
| `docker stop container_id` | Stop a running container |
| `docker rm container_id` | Remove a stopped container |

### 3. Dockerfile
A text file with **instructions to build a custom image**.

```dockerfile
# Start from an existing base image
FROM python:3.11

# Set working directory inside the container
WORKDIR /app

# Copy files from your computer into the container
COPY requirements.txt .

# Run a command during image build
RUN pip install -r requirements.txt

# Copy the rest of your code
COPY . .

# Command to run when the container starts
CMD ["python", "pipeline.py"]
```

### 4. Docker Registry
A storage service for Docker images.
- **Docker Hub** (public): [hub.docker.com](https://hub.docker.com)
- **Google Container Registry** (private, GCP)
- **AWS ECR** (private, AWS)

---

## 🚀 Hands-On Examples

### Example 1: Run a Python container interactively

```bash
# Run Python 3.13 container with bash shell
docker run -it python:3.13 bash

# Inside the container, check pip version
pip --version
# Output: pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)

# Exit the container
exit
```

**What's happening?**
- `-i` = interactive (keep stdin open)
- `-t` = allocate a TTY terminal
- `python:3.13` = the image to use
- `bash` = command to run (override the default CMD)

### Example 2: Build and Run a Custom Image

**Step 1**: Create a `pipeline.py` file:

```python
import sys
import pandas as pd

print("Pipeline started!")
print(f"Arguments received: {sys.argv}")

# Simulate a data pipeline step
day = sys.argv[1]
print(f"Processing data for day: {day}")
print("Pipeline completed!")
```

**Step 2**: Create a `Dockerfile`:

```dockerfile
FROM python:3.11

RUN pip install pandas

WORKDIR /app

COPY pipeline.py pipeline.py

ENTRYPOINT ["python", "pipeline.py"]
```

**Step 3**: Build the image:

```bash
# Build the image (name it "taxi-pipeline", version "v001")
docker build -t taxi-pipeline:v001 .
```

**Step 4**: Run the container:

```bash
# Pass "2025-01-01" as an argument to pipeline.py
docker run -it taxi-pipeline:v001 2025-01-01
```

Expected output:
```
Pipeline started!
Arguments received: ['pipeline.py', '2025-01-01']
Processing data for day: 2025-01-01
Pipeline completed!
```

---

## 🌐 Docker Networking

Containers are isolated by default. To let them communicate, Docker uses **networks**.

```bash
# Create a Docker network
docker network create pg-network

# Now containers on the same network can talk to each other by name
```

### Port Mapping: `-p host:container`

```bash
# Map port 5432 inside the container to port 5432 on your machine
docker run -p 5432:5432 postgres:17
#                ↑              ↑
#           your laptop    inside container
```

### Volume Mounting: `-v host_path:container_path`

```bash
# Mount your local folder into the container (persistent storage)
docker run -v /home/user/data:/var/lib/postgresql/data postgres:17
```

Without volumes, data disappears when the container stops!

---

## 🔑 Key Docker Commands Reference

```bash
# Images
docker pull image_name          # Download image
docker build -t name:tag .      # Build image from Dockerfile
docker images                   # List images
docker rmi image_name           # Delete image

# Containers
docker run -it image_name       # Run interactively
docker run -d image_name        # Run in background (detached)
docker run -p 8080:80 nginx     # Port mapping
docker run -v /local:/container # Volume mounting
docker ps                       # List running containers
docker ps -a                    # List all containers
docker stop container_id        # Stop container
docker rm container_id          # Remove container
docker exec -it container bash  # Enter running container

# Logs & Info
docker logs container_id        # View container logs
docker inspect container_id     # Detailed container info
```

---

## ✅ Why Docker Matters for Data Engineering

| Problem | Docker Solution |
|---------|----------------|
| "Works on my machine" | Same container everywhere |
| Different Python versions | Pin exact version in Dockerfile |
| Complex dependency conflicts | Each container is isolated |
| Scaling pipelines | Run many containers in parallel |
| Reproducible ML experiments | Lock all dependencies |
| CI/CD pipelines | Build once, deploy anywhere |

---

## 🔗 How This Connects to the Rest of the Course

```
Docker (Module 1)
    ↓ runs
PostgreSQL container → stores your pipeline data
    ↓ queried by
pgAdmin container → your database GUI
    ↓ orchestrated by
Docker Compose → runs multiple containers together
    ↓ deployed to
GCP (via Terraform) → cloud infrastructure
    ↓ used in
Module 2 (Kestra) → Kestra itself runs in Docker!
```

---

*Next: [Topic 2 - Running PostgreSQL with Docker →](02-postgres-with-docker.md)*
