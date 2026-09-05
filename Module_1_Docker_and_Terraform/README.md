# 📦 Module 1: Containerization & Infrastructure as Code (with AWS)

> **Data Engineering Zoomcamp — Module 1**  
> GitHub Source: [01-docker-terraform](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform)

---

## 🗺️ Module Overview

Module 1 is the foundation of the entire Data Engineering Zoomcamp. You will learn to:
- Containerize your data pipeline tools using **Docker**
- Set up a local **PostgreSQL** database and **pgAdmin** UI
- Ingest real NYC Taxi data into PostgreSQL using **Python**
- Use **SQL** to query and analyze the data
- Provision modern cloud infrastructure on **Amazon Web Services (AWS)** using **Terraform**:
  - **Amazon S3**: Scalable Data Lake
  - **AWS Glue Data Catalog**: Schema & metadata storage
  - **Amazon Athena**: Serverless SQL engine

---

## 📁 Folder Structure

```
Module_1_Docker_and_Terraform/
│
├── README.md                        ← You are here (Module overview)
├── 01-docker-fundamentals.md        ← Docker concepts + examples
├── 02-postgres-with-docker.md       ← Running PostgreSQL in Docker
├── 03-data-ingestion-python.md      ← Ingesting NYC Taxi data with Python
├── 04-docker-compose.md             ← Multi-container orchestration
├── 05-sql-refresher.md              ← SQL queries on real data
├── 06-aws-overview.md               ← AWS Cloud: S3, Glue, Athena, Free Tier & IAM
├── 07-terraform-concepts.md         ← Terraform basics + AWS IaC
├── 08-project.md                    ← End-to-End Module 1 Project Guide (AWS)
├── 09-homework.md                   ← Official homework questions & SQL answers
│
└── nyc_taxi_pipeline/               ← Your hands-on project folder (code it yourself!)
    ├── Dockerfile                   ← Ingestion container build
    ├── docker-compose.yaml          ← Postgres + pgAdmin + Ingest orchestration
    ├── requirements.txt             ← Python dependencies (pandas, boto3, sqlalchemy)
    ├── .env                         ← Local environment variables (AWS keys, DB creds)
    ├── scripts/
    │   ├── ingest_data.py           ← Main ingestion script
    │   └── upload_to_s3.py          ← Uploads raw data to Amazon S3
    ├── queries/
    │   ├── analysis.sql             ← Analytical SQL queries
    │   ├── homework.sql             ← Homework answer queries
    │   └── athena_queries.sql       ← Amazon Athena SQL queries over S3
    └── terraform/
        ├── main.tf                  ← AWS Terraform (S3 + Glue + Athena)
        ├── variables.tf             ← AWS region & bucket variables
        └── .gitignore               ← Ignores .tfstate and secrets
```

---

## 🎯 Learning Path (Step-by-Step)

| Step | File | What You Learn | GitHub Link |
|:---:|---|---|---|
| 1 | `01-docker-fundamentals.md` | Docker images, containers, Dockerfile | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 2 | `02-postgres-with-docker.md` | Running PostgreSQL locally in Docker | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 3 | `03-data-ingestion-python.md` | Ingesting data with Python & pandas | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 4 | `04-docker-compose.md` | Multi-container setup (Postgres + pgAdmin) | [docker-sql/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/docker-sql) |
| 5 | `05-sql-refresher.md` | Joins, aggregations, date functions | [10-sql-refresher.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/01-docker-terraform/docker-sql/10-sql-refresher.md) |
| 6 | `06-aws-overview.md` | AWS Setup: IAM, S3 Data Lake, Glue, Athena, Free Tier | [AWS Guide](06-aws-overview.md) |
| 7 | `07-terraform-concepts.md` | Terraform IaC for AWS (`aws_s3_bucket`, Athena) | [Terraform Guide](07-terraform-concepts.md) |
| 8 | `08-project.md` | End-to-end pipeline project walkthrough (AWS) | [Project Docs](08-project.md) |
| 9 | `09-homework.md` | Official graded homework questions & SQL | [homework.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/01-docker-terraform/homework.md) |

---

## 🔗 Key Resources

- 🎥 **Workshop Video**: [Docker + Postgres walkthrough](https://www.youtube.com/watch?v=lP8xXebHmuE)
- 🎥 **SQL Refresher**: [SQL Queries on NYC data](https://www.youtube.com/watch?v=QEcps_iskgg)
- 🎥 **Terraform Intro**: [Terraform Concepts](https://youtu.be/s2bOYDCKl_M)
- 🎥 **Terraform Basics**: [Simple one file deployment](https://youtu.be/Y2ux7gq3Z0o)
- 📚 **Full Playlist**: [YouTube Course Playlist](https://www.youtube.com/playlist?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)
- 💬 **Slack**: [#course-data-engineering](https://app.slack.com/client/T01ATQK62F8/C01FABYF2RG)

---

## ☁️ AWS Cloud Stack at a Glance

| Role | AWS Service | Purpose in this Course |
|:---|:---|:---|
| **Data Lake** | Amazon S3 | Store raw Parquet/CSV files with 30-day lifecycle expiration |
| **Data Catalog** | AWS Glue Data Catalog | Central metadata schema repository (`ny_taxi_db`) |
| **Query Engine** | Amazon Athena | Serverless Presto/Trino SQL engine querying directly from S3 |
| **Python SDK** | `boto3` | Script programmatic upload to S3 |
| **IaC** | Terraform (`hashicorp/aws`) | Provision S3 buckets, Glue DB, and Athena Workgroup |

---

## ⏱️ Estimated Study Time

- Total: ~8–10 hours
- Docker + Postgres: 3 hours
- SQL Refresher: 1.5 hours
- AWS + Terraform: 2.5 hours
- Hands-on Project (`nyc_taxi_pipeline`): 2–3 hours

---

*Next Module → [Module 2: Workflow Orchestration (Kestra)](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/02-workflow-orchestration)*
