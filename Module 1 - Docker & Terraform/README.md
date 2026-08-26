# 📦 Module 1: Containerization & Infrastructure as Code

> **Data Engineering Zoomcamp — Module 1**  
> GitHub Source: [01-docker-terraform](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform)

---

## 🗺️ Module Overview

Module 1 is the foundation of the entire Data Engineering Zoomcamp. You will learn to:
- Containerize your data pipeline tools using **Docker**
- Set up a local **PostgreSQL** database and **pgAdmin** UI
- Ingest real NYC Taxi data into PostgreSQL using **Python**
- Use **SQL** to query and analyze the data
- Provision cloud infrastructure on **GCP** using **Terraform**

---

## 📁 Folder Structure

```
Module 1 - Docker & Terraform/
│
├── README.md                        ← You are here (Module overview)
├── 01-docker-fundamentals.md        ← Docker concepts + examples
├── 02-postgres-with-docker.md       ← Running PostgreSQL in Docker
├── 03-data-ingestion-python.md      ← Ingesting NYC Taxi data with Python
├── 04-docker-compose.md             ← Multi-container orchestration
├── 05-sql-refresher.md              ← SQL queries on real data
├── 06-gcp-overview.md               ← Google Cloud Platform intro
├── 07-terraform-concepts.md         ← Terraform basics + GCP setup
├── 08-project.md                    ← End-to-End Module 1 Project
└── 09-homework.md                   ← Official homework questions
```

---

## 🎯 Learning Path (Step-by-Step)

| Step | File | What You Learn | GitHub Link |
|------|------|---------------|-------------|
| 1 | `01-docker-fundamentals.md` | Docker images, containers, Dockerfile | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 2 | `02-postgres-with-docker.md` | Running PostgreSQL locally in Docker | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 3 | `03-data-ingestion-python.md` | Ingesting data with Python & pandas | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 4 | `04-docker-compose.md` | Multi-container setup (Postgres + pgAdmin) | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 5 | `05-sql-refresher.md` | Joins, aggregations, window functions | [10-sql-refresher.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/01-docker-terraform/docker-sql/10-sql-refresher.md) |
| 6 | `06-gcp-overview.md` | GCP account setup, IAM, service accounts | [2_gcp_overview.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/01-docker-terraform/terraform/2_gcp_overview.md) |
| 7 | `07-terraform-concepts.md` | Terraform init/plan/apply, variables | [terraform/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/terraform) |
| 8 | `08-project.md` | Build complete local data pipeline | Project |
| 9 | `09-homework.md` | Official graded homework | [homework.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/01-docker-terraform/homework.md) |

---

## 🔗 Key Resources

- 🎥 **Workshop Video**: [Docker + Postgres walkthrough](https://www.youtube.com/watch?v=lP8xXebHmuE)
- 🎥 **GCP Intro Video**: [Introduction to GCP](https://youtu.be/18jIzE41fJ4)
- 🎥 **Terraform Intro**: [Terraform Concepts](https://youtu.be/s2bOYDCKl_M)
- 🎥 **Terraform Basics**: [Simple one file deployment](https://youtu.be/Y2ux7gq3Z0o)
- 🎥 **SQL Refresher**: [SQL Queries on NYC data](https://www.youtube.com/watch?v=QEcps_iskgg)
- 📚 **Full Playlist**: [YouTube Course Playlist](https://www.youtube.com/playlist?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)
- 💬 **Slack**: [#course-data-engineering](https://app.slack.com/client/T01ATQK62F8/C01FABYF2RG)

---

## 🔧 Prerequisites / Tools to Install

| Tool | Purpose | Install Link |
|------|---------|-------------|
| Docker Desktop | Run containers locally | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Python 3.9+ | Data ingestion scripts | [python.org](https://www.python.org/downloads/) |
| pgAdmin 4 (via Docker) | PostgreSQL GUI | Included in docker-compose |
| Google Cloud SDK | GCP command line | [cloud.google.com/sdk](https://cloud.google.com/sdk/docs/install) |
| Terraform | Infrastructure as Code | [terraform.io/downloads](https://www.terraform.io/downloads) |
| Git | Version control | [git-scm.com](https://git-scm.com/) |

---

## ⏱️ Estimated Study Time

- Total: ~8–10 hours
- Docker + Postgres: 3 hours
- SQL Refresher: 1.5 hours
- GCP + Terraform: 2.5 hours
- Project: 2–3 hours

---

*Next Module → [Module 2: Workflow Orchestration (Kestra)](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/02-workflow-orchestration)*
