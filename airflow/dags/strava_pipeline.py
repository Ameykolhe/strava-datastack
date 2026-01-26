"""Strava data pipeline DAG with extract and dbt transformation."""

from datetime import datetime, timedelta

from airflow import DAG
from airflow.datasets import Dataset
from airflow.operators.empty import EmptyOperator
from cosmos.airflow.task_group import DbtTaskGroup
from cosmos import RenderConfig

from operators.strava_extract_operator import StravaExtractOperator
from config.cosmos_config import (
    get_dbt_project_config,
    get_dbt_profile_config,
    get_dbt_execution_config,
)


# Default arguments
default_args = {
    "owner": "airflow",
    "retries": 0,
    "email_on_failure": False,
    "email_on_retry": False,
}

# Datasets for lineage
strava_api = Dataset("strava://api")
raw_duckdb = Dataset("duckdb://strava_datastack/raw")
analytics_duckdb = Dataset("duckdb://strava_datastack/analytics")
reporting_duckdb = Dataset("duckdb://strava_reporting/reporting")

# DAG definition
with DAG(
    dag_id="strava_data_pipeline",
    description="Extract Strava data, transform with dbt, and validate",
    schedule=None,  # Manual trigger only
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args=default_args,
    max_active_runs=1,  # Prevent concurrent runs
    tags=["strava", "extract", "transform", "dbt"],
    doc_md="""
    # Strava Data Pipeline

    This DAG orchestrates the Strava data pipeline:

    1. **Extract**: Pull data from Strava API using dlt
    2. **Transform**: Run dbt models to transform raw data
    3. **Validate**: Check pipeline results

    ## Manual Trigger with Parameters

    Trigger with custom date range:
    ```json
    {
      "start_date": "2024-01-01",
      "end_date": "2024-12-31"
    }
    ```

    Default: Last 30 days
    """,
) as dag:

    # Start marker
    start = EmptyOperator(task_id="start")

    # Task 1: Extract from Strava API
    extract = StravaExtractOperator(
        task_id="extract_strava_data",
        extract_start_date="{{ dag_run.conf.get('start_date') if dag_run.conf else None }}",
        extract_end_date="{{ dag_run.conf.get('end_date') if dag_run.conf else None }}",
        inlets=[strava_api],
        outlets=[raw_duckdb],
        doc_md="""
        Extracts Strava activity data using the dlt pipeline.

        If no dates provided, defaults to last 30 days (configured in extract package).
        """,
    )

    # Task 2: dbt transformations
    # Note: pool with 1 slot ensures sequential execution for DuckDB
    transform = DbtTaskGroup(
        group_id="dbt_transform",
        project_config=get_dbt_project_config(),
        profile_config=get_dbt_profile_config(),
        execution_config=get_dbt_execution_config(),
        render_config=RenderConfig(exclude=["source:*"]),
        operator_args={
            "install_deps": True,  # Run dbt deps before models
            "full_refresh": False,  # Incremental mode
            "dbt_cmd_flags": ["--threads", "1"],  # Single thread for DuckDB
            "pool": "dbt_duckdb_pool",  # Use dedicated pool with 1 slot for sequential execution
            "inlets": [raw_duckdb],
            "outlets": [analytics_duckdb, reporting_duckdb],
        },
    )

    # End marker
    end = EmptyOperator(task_id="end")

    # Define task dependencies
    start >> extract >> transform >> end
