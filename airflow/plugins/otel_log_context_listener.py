"""Bind OpenTelemetry + Airflow context into structlog for task logs."""

from __future__ import annotations

import os
from typing import Any

import structlog
from airflow.listeners import hookimpl
from opentelemetry import trace
from airflow.plugins_manager import AirflowPlugin


def _parse_traceparent(traceparent: str | None) -> dict[str, str]:
    if not traceparent:
        return {}
    parts = traceparent.split("-")
    if len(parts) < 4:
        return {}
    return {
        "trace_id": parts[1],
        "span_id": parts[2],
        "trace_flags": parts[3][:2],
    }


def _bind_task_context(task_instance: Any) -> None:
    span = trace.get_current_span()
    span_context = span.get_span_context()
    if span_context.is_valid:
        structlog.contextvars.bind_contextvars(
            trace_id=format(span_context.trace_id, "032x"),
            span_id=format(span_context.span_id, "016x"),
            trace_flags=f"{int(span_context.trace_flags):02x}",
        )
    else:
        carrier = getattr(task_instance, "context_carrier", None)
        traceparent = None
        if isinstance(carrier, dict):
            traceparent = carrier.get("traceparent")
        traceparent = traceparent or os.getenv("TRACEPARENT")
        if traceparent:
            os.environ["TRACEPARENT"] = traceparent
        structlog.contextvars.bind_contextvars(**_parse_traceparent(traceparent))

    structlog.contextvars.bind_contextvars(
        airflow_dag_id=task_instance.dag_id,
        airflow_task_id=task_instance.task_id,
        airflow_run_id=task_instance.run_id,
        airflow_try_number=str(task_instance.try_number),
        airflow_map_index=str(task_instance.map_index),
        airflow_logical_date=(
            task_instance.logical_date.isoformat()
            if getattr(task_instance, "logical_date", None)
            else ""
        ),
    )

    structlog.contextvars.bind_contextvars(
        dlt_pipeline_name=os.getenv("DLT_PIPELINE_NAME", ""),
        dlt_dataset_name=os.getenv("DLT_DATASET_NAME", ""),
        dlt_destination=os.getenv("DLT_DESTINATION", ""),
        dlt_load_id=os.getenv("DLT_LOAD_ID", ""),
    )


def _clear_context() -> None:
    structlog.contextvars.clear_contextvars()
    os.environ.pop("TRACEPARENT", None)


class OTelLogContextListener:
    """Airflow listener to bind log correlation context per task run."""

    @hookimpl
    def on_task_instance_running(self, previous_state, task_instance, **kwargs) -> None:
        _bind_task_context(task_instance)

    @hookimpl
    def on_task_instance_success(self, previous_state, task_instance, **kwargs) -> None:
        _clear_context()

    @hookimpl
    def on_task_instance_failed(self, previous_state, task_instance, **kwargs) -> None:
        _clear_context()


class OTelLogContextPlugin(AirflowPlugin):
    """Register OTel log context listener with Airflow."""

    name = "otel_log_context"
    listeners = [OTelLogContextListener()]
