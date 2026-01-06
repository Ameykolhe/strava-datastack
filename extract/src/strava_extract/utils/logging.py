"""Structured logging configuration for the Strava extract pipeline."""

import logging
import sys
import json
import uuid
from typing import Optional
from datetime import datetime
from contextvars import ContextVar


# Context variable for trace ID
trace_id_var: ContextVar[Optional[str]] = ContextVar("trace_id", default=None)


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
            datefmt="%Y-%m-%d %H:%M:%S"
        )


def setup_logging(
    level: str = "INFO",
    format_type: str = "text",
    log_file: Optional[str] = None
) -> None:
    """
    Configure application logging.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
        format_type: Format type ("json" or "text").
        log_file: Optional log file path. If None, logs to stdout.
    """
    # Get root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, level.upper()))

    # Remove existing handlers
    root_logger.handlers.clear()

    # Create handler
    if log_file:
        handler = logging.FileHandler(log_file)
    else:
        handler = logging.StreamHandler(sys.stdout)

    # Set formatter
    if format_type == "json":
        formatter = JSONFormatter()
    else:
        formatter = TextFormatter()

    handler.setFormatter(formatter)
    root_logger.addHandler(handler)

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
