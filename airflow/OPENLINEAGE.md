# OpenLineage integration

This project emits lineage events from Airflow using the OpenLineage provider.

## Configure the backend

Set one of the following environment variables (via `airflow/.env` or your shell) before running the Airflow stack:

- `AIRFLOW__OPENLINEAGE__TRANSPORT` (full JSON transport config)
- or set `OPENLINEAGE_NAMESPACE` and keep the default transport in `airflow/docker-compose.yaml`

Example (Marquez running on `http://localhost:5000`):

```
AIRFLOW__OPENLINEAGE__TRANSPORT={"type":"http","url":"http://host.docker.internal:5000","endpoint":"api/v1/lineage"}
OPENLINEAGE_NAMESPACE=strava-datastack
```

## What gets emitted

- DuckDB raw -> DuckDB analytics (from dbt task datasets)
- dbt model lineage (emitted by Cosmos via OpenLineage provider)

Evidence reads from the analytics DuckDB file; those queries are not executed via Airflow, so they are not emitted as lineage events here.

## Marquez service

`airflow/docker-compose.yaml` includes a `marquez` service and a `marquez-db` Postgres instance. The Airflow containers point at `http://marquez:5000/api/v1/lineage` by default.
