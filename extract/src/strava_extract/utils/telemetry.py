"""OpenTelemetry setup for tracing and log export."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Optional, Sequence
from urllib.parse import urljoin, urlparse

from opentelemetry import _logs as otel_logs
from opentelemetry import trace
from opentelemetry.context import attach, detach
from opentelemetry.propagate import extract
from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor


@dataclass(frozen=True)
class TelemetryConfig:
    """Runtime configuration for OpenTelemetry exporters."""

    enabled: bool
    endpoint: str
    service_name: str
    service_namespace: str
    environment: str
    enable_traces: bool
    enable_logs: bool


_requests_instrumented = False


def _with_otlp_path(endpoint: str, path: str) -> str:
    parsed = urlparse(endpoint)
    if parsed.path.endswith(path):
        return endpoint
    if parsed.path and "/v1/" in parsed.path:
        return endpoint
    base = endpoint if endpoint.endswith("/") else f"{endpoint}/"
    return urljoin(base, path.lstrip("/"))


def attach_trace_context(traceparent: Optional[str]) -> Optional[object]:
    """Attach a W3C traceparent to the current context if provided."""
    if not traceparent:
        return None
    ctx = extract({"traceparent": traceparent})
    return attach(ctx)


def detach_trace_context(token: Optional[object]) -> None:
    """Detach a previously attached context."""
    if token is not None:
        detach(token)


def setup_telemetry(config: TelemetryConfig) -> Sequence[logging.Handler]:
    """
    Configure OpenTelemetry exporters.

    Returns:
        A sequence of logging handlers to attach to the root logger.
    """
    if not config.enabled:
        return []

    resource = Resource.create(
        {
            "service.name": config.service_name,
            "service.namespace": config.service_namespace,
            "deployment.environment": config.environment,
        }
    )

    if config.enable_traces:
        tracer_provider = trace.get_tracer_provider()
        trace_exporter = OTLPSpanExporter(
            endpoint=_with_otlp_path(config.endpoint, "/v1/traces")
        )
        if isinstance(tracer_provider, TracerProvider):
            tracer_provider.add_span_processor(BatchSpanProcessor(trace_exporter))
        else:
            tracer_provider = TracerProvider(resource=resource)
            tracer_provider.add_span_processor(BatchSpanProcessor(trace_exporter))
            trace.set_tracer_provider(tracer_provider)

        global _requests_instrumented
        if not _requests_instrumented:
            RequestsInstrumentor().instrument()
            _requests_instrumented = True

    handlers: list[logging.Handler] = []
    if config.enable_logs:
        logger_provider = otel_logs.get_logger_provider()
        log_exporter = OTLPLogExporter(
            endpoint=_with_otlp_path(config.endpoint, "/v1/logs")
        )
        if isinstance(logger_provider, LoggerProvider):
            logger_provider.add_log_record_processor(
                BatchLogRecordProcessor(log_exporter)
            )
        else:
            logger_provider = LoggerProvider(resource=resource)
            logger_provider.add_log_record_processor(
                BatchLogRecordProcessor(log_exporter)
            )
            otel_logs.set_logger_provider(logger_provider)
        handlers.append(
            LoggingHandler(level=logging.NOTSET, logger_provider=logger_provider)
        )

    return handlers
