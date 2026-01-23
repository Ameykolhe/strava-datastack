# Strava Transform (dbt)

Transforms Strava activity data into analytics-ready models for Evidence dashboards.

**Stack:** DuckDB (warehouse) / Airflow (orchestration) / Evidence (BI)

## Data Flow

```
Strava API → dlt → DuckDB (raw) → dbt → DuckDB (analytics) → Evidence
```

## Model Layers

| Layer | Materialization | Naming Pattern | Example |
|-------|-----------------|----------------|---------|
| Staging | `view` | `stg_<source>__<entity>` | `stg_strava__activities` |
| Intermediate | `view` | `int_<domain>__<purpose>` | `int_strava__activity_streams` |
| Marts | `table` | `fct_<event>` / `dim_<entity>` | `fct_activities` |
| Reporting | `table` | `rpt_<subject>__<grain>` | `rpt_year__monthly` |

**Exception:** `int_strava__activity_stream_points` uses `incremental` (expensive array unnesting).

## Local Development

```bash
cd transform
source .venv/bin/activate
export DUCKDB_PATH="/path/to/strava_datastack.duckdb"
dbt deps
dbt run
```

## Commands

| Task | Command |
|------|---------|
| Full run | `dbt run` |
| Full refresh | `dbt run --full-refresh` |
| Run by tag | `dbt run --select tag:reporting` |
| Test | `dbt test` |
