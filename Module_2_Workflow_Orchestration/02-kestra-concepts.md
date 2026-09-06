# 02 — Kestra Concepts

## What is Kestra?

Kestra is an open-source, event-driven orchestration platform.  
You define workflows in **YAML** — Kestra handles execution, retries, logging, scheduling, and UI.

Official docs: https://kestra.io/docs  
Kestra GitHub: https://github.com/kestra-io/kestra

---

## The 9 Core Concepts

### 1. Flow

A **Flow** is the complete workflow definition — written in YAML.

```yaml
id: my_first_flow
namespace: tutorial

tasks:
  - id: hello
    type: io.kestra.plugin.core.log.Log
    message: "Hello, Kestra!"
```

Every flow has:
- `id` — unique name for this flow
- `namespace` — like a folder/project grouping
- `tasks` — list of steps to execute

---

### 2. Tasks

**Tasks** are the individual steps inside a flow. Each task has:
- `id` — unique name within the flow
- `type` — which Kestra plugin to use (format: `io.kestra.plugin.<group>.<Task>`)

Types of tasks:
- **Log** — print a message
- **Script** — run Python/Bash/Node code
- **HTTP** — download a file from URL
- **Database** — run SQL against PostgreSQL
- **AWS** — interact with S3, Glue, Athena
- **Sequential / Parallel** — control task execution order

```yaml
tasks:
  - id: download_file
    type: io.kestra.plugin.core.http.Download
    uri: "https://example.com/data.parquet"

  - id: run_python
    type: io.kestra.plugin.scripts.python.Script
    script: |
      print("Processing data...")
```

---

### 3. Inputs

**Inputs** are parameters you pass to a flow when you trigger it manually or via API.  
This makes flows reusable for different datasets.

```yaml
inputs:
  - id: taxi_color
    type: STRING
    defaults: green

  - id: year
    type: INT
    defaults: 2025

  - id: month
    type: INT
    defaults: 11
```

Access inputs inside tasks with: `{{ inputs.taxi_color }}`

---

### 4. Outputs

**Outputs** are data produced by one task that later tasks can consume.

```yaml
tasks:
  - id: download
    type: io.kestra.plugin.core.http.Download
    uri: "https://example.com/file.parquet"
    # This task produces: outputs.download.uri

  - id: process
    type: io.kestra.plugin.scripts.python.Script
    inputFiles:
      data.parquet: "{{ outputs.download.uri }}"
    script: |
      import pandas as pd
      df = pd.read_parquet("data.parquet")
      print(df.shape)
```

`{{ outputs.task_id.output_name }}` — Kestra's templating syntax (Pebble templates).

---

### 5. Triggers

**Triggers** automatically start a flow based on a condition.

#### Schedule Trigger (Cron)
```yaml
triggers:
  - id: monthly_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 9 1 * *"   # 9am on the 1st of every month
```

Common cron expressions:
| Cron | Meaning |
|---|---|
| `0 * * * *` | Every hour |
| `0 0 * * *` | Every day at midnight |
| `0 9 1 * *` | 9am on 1st of every month |
| `0 6 * * 1` | Every Monday at 6am |

#### Flow Trigger (chain flows)
```yaml
triggers:
  - id: after_ingest
    type: io.kestra.plugin.core.trigger.Flow
    inputs:
      namespace: tutorial
      flowId: ingest_taxi_data
```

---

### 6. Execution

An **Execution** is one run of a flow. In the Kestra UI you can see:
- Status: `SUCCESS`, `FAILED`, `RUNNING`, `PAUSED`
- Duration of each task
- Logs from each task
- Inputs used
- Outputs produced

---

### 7. Variables

**Variables** let you define reusable values within a flow.

```yaml
variables:
  bucket: ny-taxi-data-lake-abhishekshankar-826674
  region: us-east-1
  raw_prefix: raw

tasks:
  - id: upload
    type: io.kestra.plugin.aws.s3.Upload
    bucket: "{{ vars.bucket }}"
    region: "{{ vars.region }}"
```

---

### 8. Plugin Defaults

**Plugin Defaults** set default values for all tasks of a given type within a flow.  
Useful to avoid repeating AWS credentials on every task.

```yaml
pluginDefaults:
  - type: io.kestra.plugin.aws
    values:
      accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
      secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
      region: us-east-1
```

---

### 9. Concurrency

**Concurrency** controls how many executions of a flow can run simultaneously.

```yaml
concurrency:
  limit: 1   # Only 1 run at a time (prevents overlapping pipeline runs)
```

---

## Kestra Templating (Pebble Syntax)

Kestra uses **Pebble templates** for dynamic values:

| Syntax | Meaning |
|---|---|
| `{{ inputs.name }}` | Flow input value |
| `{{ outputs.task_id.uri }}` | Output from a previous task |
| `{{ vars.bucket }}` | Flow variable |
| `{{ secret('KEY') }}` | Secret from Kestra's KV store |
| `{{ trigger.date }}` | Date from the trigger |
| `{{ execution.id }}` | Current execution ID |

---

## Flow File Anatomy

```yaml
id: flow_unique_id           # Required: unique name
namespace: your.namespace    # Required: logical grouping

description: |               # Optional: human-readable description
  This flow downloads taxi data and loads it to PostgreSQL.

labels:                      # Optional: tags for filtering in UI
  module: "2"
  dataset: green_taxi

inputs:                      # Optional: runtime parameters
  - id: taxi_color
    type: STRING
    defaults: green

variables:                   # Optional: reusable values
  bucket: my-s3-bucket

tasks:                       # Required: list of steps
  - id: step_1
    type: io.kestra.plugin.core.log.Log
    message: "Starting..."

  - id: step_2
    type: io.kestra.plugin.scripts.python.Script
    script: print("Done")

triggers:                    # Optional: automatic start conditions
  - id: daily
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 9 * * *"

pluginDefaults:              # Optional: shared task config
  - type: io.kestra.plugin.aws
    values:
      region: us-east-1

concurrency:                 # Optional: execution control
  limit: 2
```

---

## Kestra UI Tour

Once Kestra is running at `http://localhost:8080`:

| Section | What it shows |
|---|---|
| **Flows** | All your YAML flow definitions |
| **Executions** | History of all runs + status |
| **Logs** | Full logs per task per execution |
| **Triggers** | All scheduled/event triggers |
| **Editor** | Write/paste YAML flows with autocomplete |
| **Plugins** | Browse all 1000+ available plugins |
| **KV Store** | Store secrets (AWS keys, DB passwords) securely |
