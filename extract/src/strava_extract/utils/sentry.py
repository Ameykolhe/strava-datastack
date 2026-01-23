"""Sentry SDK initialization and configuration for observability."""

import functools
import os
from contextlib import contextmanager
from typing import Any, Callable, Optional, TypeVar

import sentry_sdk
from sentry_sdk.integrations.logging import LoggingIntegration

from .logging import get_trace_id

# Type variable for generic function decorator
F = TypeVar("F", bound=Callable[..., Any])

# Global flag to track if Sentry is initialized
_sentry_initialized = False


def init_sentry(
    dsn: Optional[str] = None,
    environment: str = "development",
    release: Optional[str] = None,
    traces_sample_rate: float = 1.0,
    profiles_sample_rate: float = 0.1,
) -> bool:
    """
    Initialize Sentry SDK for error tracking and performance monitoring.

    Args:
        dsn: Sentry DSN. If None, reads from SENTRY_DSN environment variable.
        environment: Deployment environment (development, staging, production).
        release: Release version string.
        traces_sample_rate: Sample rate for performance tracing (0.0 to 1.0).
        profiles_sample_rate: Sample rate for profiling (0.0 to 1.0).

    Returns:
        True if Sentry was initialized, False if DSN was not provided.
    """
    global _sentry_initialized

    dsn = dsn or os.getenv("SENTRY_DSN")

    if not dsn:
        return False

    # Configure logging integration to capture breadcrumbs
    logging_integration = LoggingIntegration(
        level=None,  # Capture all log levels as breadcrumbs
        event_level="INFO",  # Send info+ logs as events
    )

    sentry_sdk.init(
        dsn=dsn,
        environment=environment,
        release=release or os.getenv("SENTRY_RELEASE", "strava-extract@0.1.0"),
        traces_sample_rate=traces_sample_rate,
        profiles_sample_rate=profiles_sample_rate,
        integrations=[logging_integration],
        send_default_pii=False,
        attach_stacktrace=True,
        max_breadcrumbs=50,
        enable_logs=True
    )

    _sentry_initialized = True
    return True


def init_sentry_from_settings() -> bool:
    """
    Initialize Sentry from application settings.

    Loads configuration from Settings and initializes Sentry if enabled.
    This is the preferred way to initialize Sentry in the application.

    Returns:
        True if Sentry was initialized, False otherwise.
    """
    try:
        from ..config.settings import get_settings

        settings = get_settings()
        sentry_config = settings.sentry

        # Check if Sentry is enabled
        if not sentry_config.enabled:
            return False

        # DSN can come from config or environment variable
        dsn = sentry_config.dsn or os.getenv("SENTRY_DSN")
        if not dsn:
            return False

        return init_sentry(
            dsn=dsn,
            environment=settings.environment,
            traces_sample_rate=sentry_config.traces_sample_rate if sentry_config.enable_tracing else 0.0,
            profiles_sample_rate=sentry_config.profiles_sample_rate if sentry_config.enable_profiling else 0.0,
        )
    except Exception:
        # Graceful degradation - don't break the pipeline if Sentry init fails
        return False


def is_sentry_initialized() -> bool:
    """Check if Sentry has been initialized."""
    return _sentry_initialized


def set_sentry_context(
    trace_id: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    pipeline_name: Optional[str] = None,
    **extra: Any,
) -> None:
    """
    Set Sentry context for the current scope.

    Args:
        trace_id: Pipeline trace ID for correlation.
        start_date: Pipeline start date parameter.
        end_date: Pipeline end date parameter.
        pipeline_name: Name of the pipeline being executed.
        **extra: Additional context key-value pairs.
    """
    # Use provided trace_id or get from context
    trace_id = trace_id or get_trace_id()

    with sentry_sdk.configure_scope() as scope:
        # Set user context with trace_id for correlation
        if trace_id:
            scope.set_tag("trace_id", trace_id)

        # Set pipeline context
        scope.set_context(
            "pipeline",
            {
                "trace_id": trace_id,
                "start_date": start_date,
                "end_date": end_date,
                "pipeline_name": pipeline_name,
                **extra,
            },
        )


def set_sentry_user(user_id: Optional[str] = None) -> None:
    """
    Set Sentry user context.

    Args:
        user_id: User identifier (e.g., Strava athlete ID).
    """
    if user_id:
        sentry_sdk.set_user({"id": user_id})


def capture_exception(
    exception: Exception,
    level: str = "error",
    extra: Optional[dict] = None,
) -> Optional[str]:
    """
    Capture an exception and send to Sentry.

    Args:
        exception: The exception to capture.
        level: Severity level (debug, info, warning, error, fatal).
        extra: Additional context to attach to the event.

    Returns:
        Event ID if captured, None otherwise.
    """
    with sentry_sdk.push_scope() as scope:
        scope.set_level(level)
        if extra:
            for key, value in extra.items():
                scope.set_extra(key, value)
        return sentry_sdk.capture_exception(exception)


def capture_message(
    message: str,
    level: str = "info",
    extra: Optional[dict] = None,
) -> Optional[str]:
    """
    Capture a message and send to Sentry.

    Args:
        message: The message to capture.
        level: Severity level (debug, info, warning, error, fatal).
        extra: Additional context to attach to the event.

    Returns:
        Event ID if captured, None otherwise.
    """
    with sentry_sdk.push_scope() as scope:
        scope.set_level(level)
        if extra:
            for key, value in extra.items():
                scope.set_extra(key, value)
        return sentry_sdk.capture_message(message)


def add_breadcrumb(
    message: str,
    category: str = "pipeline",
    level: str = "info",
    data: Optional[dict] = None,
) -> None:
    """
    Add a breadcrumb for debugging context.

    Args:
        message: Breadcrumb message.
        category: Category for grouping (e.g., "http", "pipeline", "api").
        level: Severity level.
        data: Additional data to attach.
    """
    sentry_sdk.add_breadcrumb(
        message=message,
        category=category,
        level=level,
        data=data or {},
    )


def start_transaction(
    name: str,
    op: str = "pipeline",
    description: Optional[str] = None,
) -> Any:
    """
    Start a Sentry transaction for performance monitoring.

    Args:
        name: Transaction name.
        op: Operation type (e.g., "pipeline", "http", "db").
        description: Optional description.

    Returns:
        Sentry transaction context manager.
    """
    return sentry_sdk.start_transaction(
        name=name,
        op=op,
        description=description,
    )


@contextmanager
def sentry_span(
    op: str,
    description: Optional[str] = None,
    data: Optional[dict] = None,
):
    """
    Context manager for creating a Sentry span within a transaction.

    Usage:
        with sentry_span("db.query", "Fetching activities"):
            # Do something
            pass

    Args:
        op: Operation type (e.g., "http", "db", "pipeline.step").
        description: Human-readable description.
        data: Additional data to attach to the span.

    Yields:
        The Sentry span object (or None if Sentry not initialized).
    """
    if not _sentry_initialized:
        yield None
        return

    with sentry_sdk.start_span(op=op, description=description) as span:
        if data:
            for key, value in data.items():
                span.set_data(key, value)
        yield span


def sentry_span_decorator(
    op: str,
    description: Optional[str] = None,
) -> Callable[[F], F]:
    """
    Decorator for wrapping functions in a Sentry span.

    Usage:
        @sentry_span_decorator("pipeline.step", "Processing activities")
        def process_activities():
            pass

    Args:
        op: Operation type.
        description: Human-readable description.

    Returns:
        Decorated function.
    """
    def decorator(func: F) -> F:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            desc = description or func.__name__
            with sentry_span(op, desc):
                return func(*args, **kwargs)
        return wrapper  # type: ignore
    return decorator
