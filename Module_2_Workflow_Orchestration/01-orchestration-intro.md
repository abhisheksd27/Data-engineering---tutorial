# 01 — Introduction to Workflow Orchestration

## The Problem: Manual Pipelines Break

In Module 1, you ran data pipelines like this:

```
1. python scripts/ingest_data.py ...    ← manual
2. python scripts/upload_to_s3.py ...  ← manual
3. aws athena start-query-execution ... ← manual
```

**Problems with manual pipelines:**
- If step 2 fails, step 3 still runs (wrong data in Athena)
- No visibility: did it succeed? how long did it take?
- No retries: one network error = entire pipeline dead
- No scheduling: you must remember to run it every month
- No backfill: missed 3 months of data? run manually 3 times

---

## The Solution: Workflow Orchestration

An orchestrator is like a **conductor of an orchestra**:
- Every instrument (tool/script) plays its part
- At the right time and in the right order
- If one instrument misses a note, the conductor notices and handles it

A workflow orchestrator:
- Defines the **order** of steps (tasks)
- Handles **failures** (retries, alerts, fallbacks)
- Runs on a **schedule** or triggered by events
- Provides **visibility** (logs, status, duration per task)
- Supports **backfilling** (re-run historical periods)

---

## Why Kestra?

The Data Engineering Zoomcamp uses **Kestra** because:

| Feature | Kestra |
|---|---|
| Config language | YAML (human-readable) |
| Installation | Docker Compose (easy local setup) |
| Plugins | 1000+ (AWS, Python, PostgreSQL, HTTP, etc.) |
| UI | Built-in web UI at `localhost:8080` |
| Triggers | Cron schedule, webhook, API, flow completion |
| Python support | Run inline scripts or external `.py` files |
| Open source | Yes (Apache 2.0 license) |

---

## Core Orchestration Concepts

### DAG — Directed Acyclic Graph

A DAG represents your pipeline as a graph:
- **Nodes** = tasks (download, transform, load)
- **Edges** = dependencies between tasks
- **Directed** = flows in one direction (A → B → C)
- **Acyclic** = no loops (prevents infinite cycles)

```
[Download Parquet]
       ↓
[Load to PostgreSQL] ── fails ──→ [Send Alert Email]
       ↓
[Upload to S3]
       ↓
[Trigger Athena Query]
```

### ETL vs ELT

| Pattern | Steps | When to use |
|---|---|---|
| **ETL** | Extract → Transform → Load | Transform before loading (small data) |
| **ELT** | Extract → Load → Transform | Load raw, transform in warehouse (big data) |

Module 2 uses **ELT** — raw parquet lands in S3, SQL transforms happen in Athena.

---

## Orchestration in the Data Engineering Stack

```
Data Sources (APIs, CSVs, Parquet files)
        ↓
[Kestra Orchestrator]
    ├── Download Task
    ├── Ingest to PostgreSQL Task
    ├── Upload to S3 Task
    └── Trigger Athena/Glue Task
        ↓
Data Warehouse (Athena on S3 / PostgreSQL)
        ↓
BI Tools / Analysis
```

---

## Key Terms

| Term | Definition |
|---|---|
| **Flow** | The complete workflow definition (the YAML file) |
| **Task** | A single step inside a flow |
| **Trigger** | What starts the flow (schedule, API, event) |
| **Input** | Parameters passed to a flow at runtime |
| **Output** | Data produced by a task, usable by later tasks |
| **Execution** | One run of a flow |
| **Backfill** | Running a flow for past time periods |
| **Namespace** | Logical grouping of flows (like folders) |

---

## Kestra vs Other Orchestrators

| Tool | Language | Best For |
|---|---|---|
| **Kestra** | YAML | Event-driven, any language integration |
| **Apache Airflow** | Python DAGs | Python-heavy teams |
| **Prefect** | Python | Python, cloud-native |
| **Dagster** | Python | Data assets, lineage |
| **Mage** | Python + UI | Notebooks, ML pipelines |

In the industry, Airflow is the most common. Kestra is newer and simpler for learning.  
The **concepts are transferable** — once you understand Kestra, Airflow is easy to learn.
