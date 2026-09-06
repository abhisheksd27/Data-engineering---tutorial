# 06 — Scheduling, Cron Triggers, and Backfilling

## Why Scheduling Matters

In the real world, taxi trip data is released monthly.  
Your pipeline should **automatically run** when new data is available — without anyone pressing a button.

---

## Kestra Schedule Trigger

```yaml
triggers:
  - id: monthly_schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 9 5 * *"   # 9am on the 5th of every month
    inputs:
      taxi_color: green
      year: "{{ trigger.date | date('yyyy') }}"
      month: "{{ trigger.date | date('M') | int }}"
```

**The trigger automatically passes the current date** — so your flow knows which month to process.

---

## Cron Expression Reference

```
┌─────────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌─────────── day of month (1-31)
│ │ │ ┌───────── month (1-12)
│ │ │ │ ┌─────── day of week (0=Sun, 6=Sat)
│ │ │ │ │
* * * * *
```

| Cron | Meaning |
|---|---|
| `0 9 5 * *` | 9am on 5th of every month |
| `0 0 * * *` | Midnight every day |
| `0 6 * * 1` | 6am every Monday |
| `*/15 * * * *` | Every 15 minutes |
| `0 8-18 * * 1-5` | Every hour, 8am-6pm, Mon-Fri |
| `0 9 1 1 *` | 9am on Jan 1st every year |

---

## Trigger Date Variables

When a Schedule trigger fires, these variables are available:

| Variable | Example Value | Description |
|---|---|---|
| `trigger.date` | `2025-11-05T09:00:00Z` | Full trigger timestamp |
| `trigger.date \| date('yyyy')` | `2025` | Year |
| `trigger.date \| date('MM')` | `11` | Month (zero-padded) |
| `trigger.date \| date('M')` | `11` | Month (no padding) |
| `trigger.date \| date('dd')` | `05` | Day |

**Example: Build a dynamic S3 path from trigger date:**
```yaml
key: "raw/green_tripdata_{{ trigger.date | date('yyyy') }}-{{ trigger.date | date('MM') }}.parquet"
```

---

## Flow Trigger (Chain Flows)

Trigger one flow **after another flow succeeds**:

```yaml
# In flow B (downstream)
triggers:
  - id: after_ingest_completes
    type: io.kestra.plugin.core.trigger.Flow
    conditions:
      - type: io.kestra.plugin.core.condition.ExecutionFlowCondition
        namespace: tutorial
        flowId: ingest_taxi_data
      - type: io.kestra.plugin.core.condition.ExecutionStatusCondition
        in:
          - SUCCESS
```

This replaces manual step coordination — Flow B automatically runs when Flow A finishes successfully.

---

## Backfilling: Running Historical Data

### What is Backfilling?

If your pipeline goes live in November 2025 but you need data from Jan-Oct 2025, you need to **backfill** — run the pipeline for past months.

Without Kestra, you'd manually run a script 10 times.  
With Kestra, backfill is built in.

### Backfill via Kestra UI

1. Go to **Triggers** section in the Kestra UI
2. Find your scheduled trigger
3. Click **Backfill Executions**
4. Set start date: `2025-01-01`
5. Set end date: `2025-10-31`
6. Kestra automatically creates executions for each month in the range

### Backfill via Kestra API

```bash
curl -X POST http://localhost:8080/api/v1/triggers/{namespace}/{flowId}/backfill \
  -H "Content-Type: application/json" \
  -d '{
    "start": "2025-01-01T00:00:00Z",
    "end": "2025-10-31T00:00:00Z"
  }'
```

---

## Concurrency: Preventing Overlapping Runs

If a scheduled run is still processing when the next one fires, you might corrupt your data.  
Use `concurrency` to prevent this:

```yaml
concurrency:
  limit: 1     # Only 1 execution at a time
  behavior: WAIT   # Queue new runs (alternative: CANCEL or FAIL)
```

Options for `behavior`:
| Behavior | Effect |
|---|---|
| `WAIT` | New execution queues until current one finishes |
| `CANCEL` | New execution cancels the current one |
| `FAIL` | New execution fails immediately |

For a monthly data pipeline: use `limit: 1` with `WAIT`.

---

## Pause and Resume

Some pipelines need a human approval step in the middle:

```yaml
tasks:
  - id: load_data
    type: io.kestra.plugin.scripts.python.Script
    script: ...

  - id: wait_for_approval
    type: io.kestra.plugin.core.flow.Pause
    timeout: PT24H   # Auto-resume after 24 hours if no action

  - id: send_to_production
    type: io.kestra.plugin.scripts.python.Script
    script: ...
```

The execution pauses at `wait_for_approval`. In the Kestra UI, you click **Resume** to continue.

---

## Monitoring: How to Know if Your Pipeline is Healthy

### Kestra UI Monitoring
- **Executions** page: see all runs, filter by status, date, flow
- **Gantt chart** per execution: shows each task's duration
- **Logs** per task: full stdout/stderr

### Key Metrics to Watch
| Metric | Healthy Sign |
|---|---|
| Last execution status | SUCCESS |
| Task duration | Consistent (no sudden spikes) |
| Retry count | 0 (retries = transient failures) |
| Rows inserted | Matches expected data volume |

---

## Real-World Scheduling Pattern for Taxi Data

```yaml
# Flow: Monthly NYC Taxi Ingest (Green + Yellow)
triggers:
  - id: green_monthly
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 9 5 * *"
    inputs:
      taxi_color: green
      year: "{{ trigger.date | date('yyyy') }}"
      month: "{{ trigger.date | date('M') | int }}"

  - id: yellow_monthly
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 10 5 * *"   # 1 hour after green (avoid S3 rate limits)
    inputs:
      taxi_color: yellow
      year: "{{ trigger.date | date('yyyy') }}"
      month: "{{ trigger.date | date('M') | int }}"
```

This runs twice monthly: once for green taxi, once for yellow.
