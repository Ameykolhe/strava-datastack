"""Airflow logging config with OpenTelemetry trace IDs."""

from __future__ import annotations

import json
import logging
import os
from datetime import datetime
from copy import deepcopy

from airflow.config_templates.airflow_local_settings import DEFAULT_LOGGING_CONFIG
from opentelemetry import trace


def _set_if_value(record: logging.LogRecord, key: str, value: str | None) -> None:
    if value:
        setattr(record, key, value)


def _parse_traceparent(traceparent: str | None) -> tuple[str | None, str | None, str | None]:
    if not traceparent:
        return None, None, None
    parts = traceparent.split("-")
    if len(parts) < 4:
        return None, None, None
    return parts[1], parts[2], parts[3][:2]


class OTelJSONFormatter(logging.Formatter):
    """JSON formatter that preserves trace/log correlation fields."""

    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname.lower(),
            "event": record.getMessage(),
            "logger": record.name,
            "filename": record.filename,
            "lineno": record.lineno,
        }

        for key in (
            "trace_id",
            "span_id",
            "trace_flags",
            "airflow_dag_id",
            "airflow_task_id",
            "airflow_run_id",
            "airflow_try_number",
            "airflow_map_index",
            "airflow_logical_date",
            "dlt_pipeline_name",
            "dlt_dataset_name",
            "dlt_destination",
            "dlt_load_id",
        ):
            value = getattr(record, key, None)
            if value and value != "-":
                log_data[key] = value

        if getattr(record, "category", None):
            log_data["category"] = record.category
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        if getattr(record, "extra_fields", None):
            log_data.update(record.extra_fields)

        return json.dumps(log_data)


class OTelTraceIdFilter(logging.Filter):
    """Attach OpenTelemetry and Airflow context fields to log records."""

    def filter(self, record: logging.LogRecord) -> bool:
        if getattr(record, "_otel_context_injected", False):
            return True

        span = trace.get_current_span()
        span_context = span.get_span_context()
        trace_id = None
        span_id = None
        trace_flags = None
        if span_context.is_valid:
            trace_id = format(span_context.trace_id, "032x")
            span_id = format(span_context.span_id, "016x")
            trace_flags = f"{int(span_context.trace_flags):02x}"
        else:
            trace_id, span_id, trace_flags = _parse_traceparent(
                os.getenv("TRACEPARENT") or os.getenv("STRAVA_TRACEPARENT")
            )

        record.trace_id = trace_id or "-"
        record.span_id = span_id or "-"
        record.trace_flags = trace_flags or "00"

        _set_if_value(record, "airflow_dag_id", os.getenv("AIRFLOW_CTX_DAG_ID"))
        _set_if_value(record, "airflow_task_id", os.getenv("AIRFLOW_CTX_TASK_ID"))
        _set_if_value(
            record,
            "airflow_run_id",
            os.getenv("AIRFLOW_CTX_DAG_RUN_ID") or os.getenv("AIRFLOW_CTX_RUN_ID"),
        )
        _set_if_value(
            record,
            "airflow_try_number",
            os.getenv("AIRFLOW_CTX_TRY_NUMBER"),
        )
        _set_if_value(
            record,
            "airflow_map_index",
            os.getenv("AIRFLOW_CTX_MAP_INDEX"),
        )
        _set_if_value(
            record,
            "airflow_logical_date",
            os.getenv("AIRFLOW_CTX_LOGICAL_DATE")
            or os.getenv("AIRFLOW_CTX_EXECUTION_DATE"),
        )

        _set_if_value(record, "dlt_pipeline_name", os.getenv("DLT_PIPELINE_NAME"))
        _set_if_value(record, "dlt_dataset_name", os.getenv("DLT_DATASET_NAME"))
        _set_if_value(record, "dlt_destination", os.getenv("DLT_DESTINATION"))
        _set_if_value(record, "dlt_load_id", os.getenv("DLT_LOAD_ID"))

        message = record.getMessage()
        if record.trace_id != "-" and "trace_id" not in message:
            suffix = f" trace_id={record.trace_id}"
            if record.span_id != "-":
                suffix += f" span_id={record.span_id}"
            record.msg = f"{message}{suffix}"
            record.args = ()

        record._otel_context_injected = True
        return True


def _append_trace_context(formatters: dict) -> None:
    for formatter in formatters.values():
        fmt = formatter.get("format")
        if not fmt:
            continue
        if "%(trace_id)s" not in fmt:
            fmt = f"{fmt} trace_id=%(trace_id)s"
        if "%(span_id)s" not in fmt:
            fmt = f"{fmt} span_id=%(span_id)s"
        if "%(trace_flags)s" not in fmt:
            fmt = f"{fmt} trace_flags=%(trace_flags)s"
        formatter["format"] = fmt


LOGGING_CONFIG = deepcopy(DEFAULT_LOGGING_CONFIG)
LOGGING_CONFIG.setdefault("filters", {})
LOGGING_CONFIG["filters"]["otel_trace_id"] = {
    "()": "logging_config.OTelTraceIdFilter"
}
LOGGING_CONFIG.setdefault("formatters", {})
LOGGING_CONFIG["formatters"]["otel_json"] = {
    "()": "logging_config.OTelJSONFormatter"
}

# Airflow expects this symbol to exist even when remote logging is disabled.
REMOTE_TASK_LOG = None

for handler in LOGGING_CONFIG.get("handlers", {}).values():
    filters = handler.get("filters")
    if filters is None:
        handler["filters"] = ["otel_trace_id"]
    elif "otel_trace_id" not in filters:
        handler["filters"] = [*filters, "otel_trace_id"]

    formatter = handler.get("formatter")
    if isinstance(formatter, str) and "json" in formatter.lower():
        handler["formatter"] = "otel_json"

_append_trace_context(LOGGING_CONFIG.get("formatters", {}))
