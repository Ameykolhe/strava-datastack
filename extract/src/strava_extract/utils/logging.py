"""Structured logging configuration for the Strava extract pipeline."""

import json
import logging
import os
import sys
import uuid
from contextvars import ContextVar
from datetime import datetime
from typing import Optional, Sequence

from opentelemetry import trace

# Context variable for trace ID
trace_id_var: ContextVar[Optional[str]] = ContextVar("trace_id", default=None)
span_id_var: ContextVar[Optional[str]] = ContextVar("span_id", default=None)
trace_flags_var: ContextVar[Optional[str]] = ContextVar("trace_flags", default=None)


def _set_if_value(log_data: dict[str, object], key: str, value: Optional[str]) -> None:
    if value:
        log_data[key] = value


class JSONFormatter(logging.Formatter):
    """JSON formatter for structured logging."""

    def format(self, record: logging.LogRecord) -> str:
        """
        Format log record as JSON.

        Args:
            record: Log record to format.

        Returns:
            JSON-formatted log string.
        """
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        # Add trace ID if available
        trace_id = trace_id_var.get()
        if trace_id:
            log_data["trace_id"] = trace_id
        span_id = span_id_var.get()
        if span_id:
            log_data["span_id"] = span_id
        trace_flags = trace_flags_var.get()
        if trace_flags:
            log_data["trace_flags"] = trace_flags

        _set_if_value(log_data, "airflow.dag_id", os.getenv("AIRFLOW_CTX_DAG_ID"))
        _set_if_value(log_data, "airflow.task_id", os.getenv("AIRFLOW_CTX_TASK_ID"))
        _set_if_value(
            log_data,
            "airflow.run_id",
            os.getenv("AIRFLOW_CTX_DAG_RUN_ID") or os.getenv("AIRFLOW_CTX_RUN_ID"),
        )
        _set_if_value(
            log_data,
            "airflow.try_number",
            os.getenv("AIRFLOW_CTX_TRY_NUMBER"),
        )
        _set_if_value(
            log_data,
            "airflow.map_index",
            os.getenv("AIRFLOW_CTX_MAP_INDEX"),
        )
        _set_if_value(
            log_data,
            "airflow.logical_date",
            os.getenv("AIRFLOW_CTX_LOGICAL_DATE")
            or os.getenv("AIRFLOW_CTX_EXECUTION_DATE"),
        )

        _set_if_value(log_data, "dlt.pipeline_name", os.getenv("DLT_PIPELINE_NAME"))
        _set_if_value(log_data, "dlt.dataset_name", os.getenv("DLT_DATASET_NAME"))
        _set_if_value(log_data, "dlt.destination", os.getenv("DLT_DESTINATION"))
        _set_if_value(log_data, "dlt.load_id", os.getenv("DLT_LOAD_ID"))

        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)

        # Add extra fields if present
        if hasattr(record, "extra_fields"):
            log_data.update(record.extra_fields)

        return json.dumps(log_data)


class TextFormatter(logging.Formatter):
    """Human-readable text formatter for local development."""

    def __init__(self):
        """Initialize text formatter with standard format."""
        super().__init__(
            fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

    def format(self, record: logging.LogRecord) -> str:
        message = super().format(record)
        trace_id = trace_id_var.get()
        span_id = span_id_var.get()
        if trace_id and span_id:
            return f"{message} trace_id={trace_id} span_id={span_id}"
        if trace_id:
            return f"{message} trace_id={trace_id}"
        return message


class TraceContextFilter(logging.Filter):
    """Attach the current OpenTelemetry trace ID to log records."""

    def filter(self, record: logging.LogRecord) -> bool:
        span = trace.get_current_span()
        span_context = span.get_span_context()
        if span_context.is_valid:
            trace_id_var.set(format(span_context.trace_id, "032x"))
            span_id_var.set(format(span_context.span_id, "016x"))
            trace_flags_var.set(f"{int(span_context.trace_flags):02x}")
        return True


def setup_logging(
    level: str = "INFO",
    format_type: str = "text",
    log_file: Optional[str] = None,
    include_trace_id: bool = True,
    extra_handlers: Optional[Sequence[logging.Handler]] = None,
) -> None:
    """
    Configure application logging.

    Logs are always output to console. If log_file is specified,
    logs are also written to the file (dual output).

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
        format_type: Format type ("json" or "text").
        log_file: Optional log file path. If specified, logs to both console and file.
        include_trace_id: Whether to include trace IDs in log output.
        extra_handlers: Optional extra handlers to attach (e.g., OTLP logging).
    """
    # Get root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, level.upper()))

    # Remove existing handlers
    root_logger.handlers.clear()
    root_logger.filters.clear()

    # Set formatter based on format type
    formatter: logging.Formatter
    if format_type == "json":
        formatter = JSONFormatter()
    else:
        formatter = TextFormatter()

    # Always add console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)

    # Add file handler if log_file is specified (dual output)
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(formatter)
        root_logger.addHandler(file_handler)

    if extra_handlers:
        for handler in extra_handlers:
            root_logger.addHandler(handler)

    if include_trace_id:
        root_logger.addFilter(TraceContextFilter())

    # Silence noisy third-party loggers
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger with the given name.

    Args:
        name: Logger name (typically __name__).

    Returns:
        Configured logger instance.
    """
    return logging.getLogger(name)


def set_trace_id(trace_id: Optional[str] = None) -> str:
    """
    Set trace ID for request tracking.

    Args:
        trace_id: Trace ID to set. If None, generates a new UUID.

    Returns:
        The trace ID that was set.
    """
    if trace_id is None:
        trace_id = str(uuid.uuid4())
    trace_id_var.set(trace_id)
    return trace_id


def get_trace_id() -> Optional[str]:
    """
    Get current trace ID.

    Returns:
        Current trace ID or None.
    """
    return trace_id_var.get()
