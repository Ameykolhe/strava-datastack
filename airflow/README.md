# Airflow DAGs and Operators

Airflow orchestration components for the Strava data pipeline.

## DAG: strava_data_pipeline

The main pipeline DAG orchestrates data extraction and transformation.

```
start → extract_strava_data → dbt_transform → end
```

### Configuration

| Setting         | Value                                   |
|-----------------|-----------------------------------------|
| DAG ID          | `strava_data_pipeline`                  |
| Schedule        | Manual trigger only                     |
| Max Active Runs | 1                                       |
| Tags            | `strava`, `extract`, `transform`, `dbt` |

### Tasks

| Task                  | Type                  | Description                  |
|-----------------------|-----------------------|------------------------------|
| `start`               | EmptyOperator         | Pipeline start marker        |
| `extract_strava_data` | StravaExtractOperator | Extract data from Strava API |
| `dbt_transform`       | DbtTaskGroup (Cosmos) | Run all dbt models           |
| `end`                 | EmptyOperator         | Pipeline end marker          |

## Triggering the Pipeline

### Via Makefile

```bash
cd airflow

# Default: last 30 days
make trigger

# With custom date range
make trigger START_DATE=2024-01-01 END_DATE=2024-12-31
```

### Via Airflow CLI

```bash
# Trigger with default dates
docker compose exec airflow-worker airflow dags trigger strava_data_pipeline

# Trigger with parameters
docker compose exec airflow-worker airflow dags trigger strava_data_pipeline \
  --conf '{"start_date": "2024-01-01", "end_date": "2024-12-31"}'
```

### Via Airflow UI

1. Open http://localhost:8080
2. Navigate to DAGs → `strava_data_pipeline`
3. Click "Trigger DAG" (play button)
4. Optionally provide configuration JSON:
   ```json
   {
     "start_date": "2024-01-01",
     "end_date": "2024-12-31"
   }
   ```

## Required Airflow Variables

Set these variables in the Airflow UI (Admin → Variables) or via CLI:

| Variable               | Description              |
|------------------------|--------------------------|
| `STRAVA_CLIENT_ID`     | Strava API client ID     |
| `STRAVA_CLIENT_SECRET` | Strava API client secret |
| `STRAVA_REFRESH_TOKEN` | OAuth refresh token      |

### Set via CLI

```bash
docker compose exec airflow-worker airflow variables set STRAVA_CLIENT_ID "your_client_id"
docker compose exec airflow-worker airflow variables set STRAVA_CLIENT_SECRET "your_client_secret"
docker compose exec airflow-worker airflow variables set STRAVA_REFRESH_TOKEN "your_refresh_token"
```

## Custom Operators

### StravaExtractOperator

Located in `plugins/operators/strava_extract_operator.py`.

Executes the dlt extraction pipeline with:

- Automatic credential retrieval from Airflow Variables
- OpenTelemetry trace propagation
- Schema lineage extraction
- XCom return of load statistics

**Template fields:**

- `extract_start_date`: Start date (YYYY-MM-DD)
- `extract_end_date`: End date (YYYY-MM-DD)

**Returns (XCom):**

```python
{
    "start_date": "2024-01-01",
    "end_date": "2024-12-31",
    "load_info": "...",
    "lineage": {"tables": {...}},
    "destination": "duckdb",
    "dataset": "strava_raw"
}
```

## Plugins

### logging_config.py

Custom logging configuration that:

- Adds OpenTelemetry trace IDs to all log records
- Provides JSON formatter for structured logging
- Correlates logs with distributed traces

### otel_log_context_listener.py

Airflow listener plugin that:

- Binds trace context to structlog on task start
- Includes Airflow context (dag_id, task_id, run_id)
- Includes dlt context (pipeline_name, load_id)
- Clears context on task completion

## Cosmos Configuration

dbt integration via [astronomer-cosmos](https://astronomer.github.io/astronomer-cosmos/).

Located in `dags/config/cosmos_config.py`:

```python
# Project configuration
ProjectConfig(
    dbt_project_path="/opt/airflow/transform",
    models_relative_path="models",
)

# Profile configuration
ProfileConfig(
    profile_name="strava_transform",
    target_name="dev",
    profiles_yml_filepath="/opt/airflow/transform/profiles.yml",
)

# Execution configuration
ExecutionConfig(
    dbt_executable_path="/usr/local/bin/dbt",
    execution_mode=ExecutionMode.LOCAL,
)
```

### DbtTaskGroup Settings

```python
DbtTaskGroup(
    operator_args={
        "install_deps": True,
        "full_refresh": False,
        "dbt_cmd_flags": ["--threads", "1"],  # Single thread for DuckDB
        "pool": "dbt_duckdb_pool",
    },
)
```

## Directory Structure

```
airflow/
├── dags/
│   ├── strava_pipeline.py       # Main pipeline DAG
│   └── config/
│       └── cosmos_config.py     # dbt/Cosmos configuration
├── plugins/
│   ├── __init__.py
│   ├── logging_config.py        # Custom logging with OTEL
│   ├── otel_log_context_listener.py  # Task context binding
│   └── operators/
│       ├── __init__.py
│       └── strava_extract_operator.py
├── tests/
└── Makefile                     # Pipeline trigger commands
```

## Dataset Lineage

The DAG defines datasets for OpenLineage tracking:

| Dataset          | URI                                   | Description       |
|------------------|---------------------------------------|-------------------|
| Strava API       | `strava://api`                        | Source API        |
| Raw DuckDB       | `duckdb://strava_datastack/raw`       | Extracted data    |
| Analytics DuckDB | `duckdb://strava_datastack/analytics` | Transformed marts |
| Reporting DuckDB | `duckdb://strava_reporting/reporting` | Reporting models  |

These enable data-aware scheduling and lineage visualization in Marquez.
