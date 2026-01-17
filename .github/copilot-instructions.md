# Copilot instructions for strava-datastack

## Big picture (data flow + boundaries)
- Monorepo with four independent subprojects: `extract/` (Python+dlt), `transform/` (dbt), `visualize/` (Evidence), `airflow/` (Dockerized orchestration). See [Makefile](Makefile).
- Primary flow: Strava API → dlt extract → DuckDB file → dbt models → Evidence dashboards. The Airflow DAG wires extract → dbt → validation in [airflow/dags/strava_pipeline.py](airflow/dags/strava_pipeline.py).
- DuckDB file is the shared contract. Locally it lives at `strava_datastack.duckdb` (repo root). In Airflow it mounts to `/opt/airflow/data/strava_datastack.duckdb` (see [airflow/docker-compose.yaml](airflow/docker-compose.yaml)).
- Raw data lands in dataset `strava_raw` (dlt) and dbt writes to schema `dbt_sandbox` by default (see [extract/src/strava_extract/config/settings.py](extract/src/strava_extract/config/settings.py) and [transform/profiles.yml](transform/profiles.yml)). Evidence sources query `dbt_sandbox` views/tables in [visualize/sources/strava](visualize/sources/strava).

## Critical workflows (use Makefiles)
- Root convenience targets in [Makefile](Makefile): `make extract`, `make transform`, `make visualize`, `make airflow-up`, `make pipeline` (local extract→transform), `make pipeline-airflow`.
- Extract (Python 3.11, uv): install/run via [extract/Makefile](extract/Makefile). Config in [extract/config/config.yaml](extract/config/config.yaml); secrets in `extract/.env`.
- Transform (dbt + DuckDB): all dbt commands set `DUCKDB_PATH=../strava_datastack.duckdb` in [transform/Makefile](transform/Makefile). Use `make -C transform deps/run/test/docs`.
- Airflow: Docker Compose workflow in [airflow/Makefile](airflow/Makefile). First-time `make -C airflow init`, then `make -C airflow up`. Credentials are copied from `extract/.env` into Airflow Variables via `make -C airflow credentials` (runs [airflow/scripts/create-connections.sh](airflow/scripts/create-connections.sh)).
- Evidence UI: npm-based workflow in [visualize/Makefile](visualize/Makefile); sources are defined in [visualize/sources/strava/connection.yaml](visualize/sources/strava/connection.yaml).

## Project-specific conventions
- Airflow DAG uses a custom operator to run the extract package; it templates `extract_start_date`/`extract_end_date` and normalizes "None" strings. See [airflow/plugins/operators/strava_extract_operator.py](airflow/plugins/operators/strava_extract_operator.py).
- Airflow dbt tasks must run sequentially due to DuckDB locking: `dbt_duckdb_pool` with a single slot is created in [airflow/docker-compose.yaml](airflow/docker-compose.yaml) and used in [airflow/dags/strava_pipeline.py](airflow/dags/strava_pipeline.py).
- dbt models guard optional columns using the `safe_column()` macro. When adding optional fields, prefer `{{ safe_column('col', 'type') }}`; see [transform/macros/safe_column.sql](transform/macros/safe_column.sql).

## Integration points
- Extract uses dlt with pipeline name `strava_datastack` and dataset `strava_raw` (see [extract/src/strava_extract/pipeline.py](extract/src/strava_extract/pipeline.py)).
- Evidence reads from DuckDB using relative path in [visualize/sources/strava/connection.yaml](visualize/sources/strava/connection.yaml) and queries dbt marts (e.g., [visualize/sources/strava/activities_by_sport.sql](visualize/sources/strava/activities_by_sport.sql)).
- Airflow’s Cosmos config points dbt to `/opt/airflow/transform` and `profiles.yml` (see [airflow/dags/config/cosmos_config.py](airflow/dags/config/cosmos_config.py)).
