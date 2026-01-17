# AGENTS.md instructions for /Users/ameyk/PycharmProjects/strava-datastack

<INSTRUCTIONS>
## Tech stack and conventions
- extract/: Python 3.11+, uv, dlt, Pydantic, pytest, ruff, mypy, black, isort. Keep type hints and tests with pytest.
- transform/: dbt + DuckDB; use `DUCKDB_PATH` env var; model tests live in YAML and `transform/tests/`.
- visualize/: Evidence (Svelte) with npm; sources in `visualize/sources/`; components in `visualize/components/`.
- airflow/: Apache Airflow via Docker Compose; DAGs in `airflow/dags/`; operators in `airflow/plugins/`.

## Build and test commands
- Root: `make help`, `make install-all`, `make pipeline`, `make pipeline-airflow`.
- Extract: `make -C extract install`, `make -C extract run`, `make -C extract test`, `make -C extract lint`, `make -C extract format`, `make -C extract check`.
- Transform: `make -C transform deps`, `make -C transform run`, `make -C transform test`, `make -C transform docs`.
- Visualize: `make -C visualize dev`, `make -C visualize build`, `make -C visualize sources`, `make -C visualize test`.
- Airflow: `make -C airflow build`, `make -C airflow init`, `make -C airflow up`, `make -C airflow logs`, `make -C airflow trigger`.

## Data sources and paths
- Primary DuckDB file: `strava_datastack.duckdb` in repo root; Airflow uses `/opt/airflow/data/strava_datastack.duckdb`.
- Secrets: `extract/.env` (do not commit); template at `extract/.env.example`.
- dlt state: `.dlt/` directory (generated).
- Evidence source: `visualize/sources/strava/connection.yaml` points to `strava_datastack.duckdb`.
- Airflow runtime data/logs live under `airflow/data/` and `airflow/logs/`; do not delete or rewrite unless asked.
</INSTRUCTIONS>
