"""Strava data pipeline DAG with extract and dbt transformation."""

from datetime import datetime, timedelta

from airflow import DAG
from airflow.decorators import task
from airflow.sdk import get_current_context
from airflow.operators.empty import EmptyOperator
from cosmos.airflow.task_group import DbtTaskGroup
from cosmos import RenderConfig

from operators.strava_extract_operator import StravaExtractOperator
from config.cosmos_config import (
    get_dbt_project_config,
    get_dbt_profile_config,
    get_dbt_execution_config,
)

_SENTRY_TASK_TRANSACTIONS = {}


def _sentry_task_key(context) -> str:
    return f"{context['dag'].dag_id}:{context['task'].task_id}:{context.get('run_id')}"


def _get_sentry_trace_context(context):
    ti = context.get("ti")
    trace_ctx = ti.xcom_pull(task_ids="start_trace") if ti else None
    if not isinstance(trace_ctx, dict):
        return None, None
    return trace_ctx.get("sentry_trace"), trace_ctx.get("sentry_baggage")


def _set_sentry_env_from_xcom(context) -> None:
    import os

    traceparent, baggage = _get_sentry_trace_context(context)
    if traceparent:
        os.environ["SENTRY_TRACE"] = traceparent
    if baggage:
        os.environ["SENTRY_BAGGAGE"] = baggage


def _sentry_task_start(context) -> None:
    import sentry_sdk

    _set_sentry_env_from_xcom(context)
    traceparent, baggage = _get_sentry_trace_context(context)
    if traceparent or baggage:
        headers = {}
        if traceparent:
            headers["sentry-trace"] = traceparent
        if baggage:
            headers["baggage"] = baggage
        transaction = sentry_sdk.continue_trace(
            headers,
            op="airflow.task",
            name=f"airflow.{context['dag'].dag_id}.{context['task'].task_id}",
        )
    else:
        transaction = sentry_sdk.start_transaction(
            name=f"airflow.{context['dag'].dag_id}.{context['task'].task_id}",
            op="airflow.task",
        )
    _SENTRY_TASK_TRANSACTIONS[_sentry_task_key(context)] = transaction
    sentry_sdk.Hub.current.scope.set_span(transaction)


def _sentry_task_finish(context, status: str) -> None:
    transaction = _SENTRY_TASK_TRANSACTIONS.pop(_sentry_task_key(context), None)
    if transaction:
        transaction.set_status(status)
        transaction.finish()


def _sentry_task_success(context) -> None:
    _sentry_task_finish(context, "ok")


def _sentry_task_failure(context) -> None:
    _sentry_task_finish(context, "internal_error")


@task(task_id="start_trace")
def start_trace():
    import sentry_sdk

    context = get_current_context()
    dag_id = context["dag"].dag_id
    run_id = context.get("run_id")
    transaction = sentry_sdk.start_transaction(
        name=f"airflow.{dag_id}.run",
        op="airflow.dag",
        description=f"DAG run {run_id}",
    )

    if hasattr(transaction, "to_traceparent"):
        traceparent = transaction.to_traceparent()
    else:
        trace_id = transaction.trace_id.hex if hasattr(transaction.trace_id, "hex") else str(transaction.trace_id)
        span_id = transaction.span_id
        sampled = "1" if transaction.sampled else "0"
        traceparent = f"{trace_id}-{span_id}-{sampled}"

    if hasattr(transaction, "to_baggage"):
        baggage = transaction.to_baggage()
    elif hasattr(transaction, "get_baggage"):
        baggage = transaction.get_baggage()
    else:
        baggage = None

    if baggage is not None and not isinstance(baggage, str):
        if hasattr(baggage, "to_header"):
            baggage = baggage.to_header()
        else:
            baggage = str(baggage)

    transaction.finish()
    return {"sentry_trace": traceparent, "sentry_baggage": baggage}


# Default arguments
default_args = {
    "owner": "airflow",
    "retries": 0,
    "email_on_failure": False,
    "email_on_retry": False,
}

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

    trace = start_trace()

    # Task 1: Extract from Strava API
    extract = StravaExtractOperator(
        task_id="extract_strava_data",
        extract_start_date="{{ dag_run.conf.get('start_date') if dag_run.conf else None }}",
        extract_end_date="{{ dag_run.conf.get('end_date') if dag_run.conf else None }}",
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
            "on_execute_callback": _sentry_task_start,
            "on_success_callback": _sentry_task_success,
            "on_failure_callback": _sentry_task_failure,
        },
    )

    # End marker
    end = EmptyOperator(task_id="end")

    # Define task dependencies
    start >> trace >> extract >> transform >> end
