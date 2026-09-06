# Module 2: Workflow Orchestration with Kestra

## Overview

Module 1 taught us how to manually ingest data, run Docker containers, and manage infrastructure with Terraform.  
**Module 2 automates all of that** using Kestra — an open-source workflow orchestration platform that turns your scripts into reliable, scheduled, observable pipelines.

---

## What You Will Learn

| Topic | File |
|---|---|
| What is workflow orchestration & why it matters | `01-orchestration-intro.md` |
| Kestra concepts: Flows, Tasks, Triggers, Inputs, Outputs | `02-kestra-concepts.md` |
| Installing Kestra with Docker Compose | `03-kestra-docker-setup.md` |
| Building ETL pipelines (PostgreSQL + AWS S3) | `04-etl-pipelines-kestra.md` |
| AWS integration: S3, Glue, Athena via Kestra | `05-aws-integration.md` |
| Scheduling, cron triggers, and backfilling | `06-scheduling-backfill.md` |
| Hands-on Project | `07-project.md` |
| Homework | `08-homework.md` |

---

## Hands-On Project: `nyc_taxi_pipeline_m2/`

Builds on Module 1. Instead of running Python scripts manually, Kestra orchestrates them.

```
nyc_taxi_pipeline_m2/
├── docker-compose.yaml       ← Kestra + PostgreSQL services
├── .env                      ← DB creds + AWS credentials
├── README.md                 ← Project setup guide
├── flows/                    ← Kestra YAML workflow definitions
│   ├── 01_hello_world.yaml
│   ├── 02_python_task.yaml
│   ├── 03_postgres_taxi.yaml
│   ├── 04_postgres_taxi_scheduled.yaml
│   ├── 05_aws_s3_taxi.yaml
│   └── 06_aws_s3_taxi_scheduled.yaml
├── scripts/                  ← Python scripts called by Kestra tasks
│   ├── ingest_postgres.py
│   └── upload_s3.py
├── queries/                  ← SQL for validation and analysis
│   ├── postgres_analysis.sql
│   └── athena_queries.sql
├── data/                     ← Local data (gitignored)
└── terraform/                ← (Optional) extend Module 1 infra
    ├── main.tf
    └── variables.tf
```

---

## Cloud Stack (AWS Only)

| Tool | Purpose |
|---|---|
| **Kestra** | Orchestration engine (runs in Docker) |
| **PostgreSQL** | Analytical store (same as Module 1) |
| **AWS S3** | Data lake (`ny-taxi-data-lake-abhishekshankar-826674`) |
| **AWS Glue** | Catalog for Athena queries |
| **AWS Athena** | SQL on S3 |
| **Terraform** | Manage AWS infra as code |
| **Docker Compose** | Run Kestra + PostgreSQL locally |

---

## Prerequisites

- Module 1 completed (Docker, PostgreSQL, AWS S3, Terraform all working)
- Docker Desktop running
- AWS CLI configured with `--region us-east-1`
- Conda env `de-zoomcamp` active
- S3 bucket: `ny-taxi-data-lake-abhishekshankar-826674` (from Module 1 Terraform)

---

## Learning Path

```
01-orchestration-intro  →  02-kestra-concepts  →  03-kestra-docker-setup
        ↓
04-etl-pipelines-kestra  →  05-aws-integration  →  06-scheduling-backfill
        ↓
07-project (hands-on)  →  08-homework
```
