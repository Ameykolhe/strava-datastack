"""Main pipeline orchestration for Strava data extraction."""

from datetime import datetime
from typing import Optional

import dlt
from dlt.common.pipeline import LoadInfo
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

import os

from .client.rate_limiter import RateLimitExceededError
from .config.settings import get_settings
from .sources.strava_source import strava_source
from .utils.exceptions import PipelineError
from .utils.logging import get_logger, set_trace_id, setup_logging
from .utils.telemetry import (
    TelemetryConfig,
    attach_trace_context,
    detach_trace_context,
    setup_telemetry,
)
from .utils.validators import validate_date_range, validate_date_string

logger = get_logger(__name__)


def _set_airflow_span_attributes(span: trace.Span) -> None:
    span.set_attribute("airflow.dag_id", os.getenv("AIRFLOW_CTX_DAG_ID", ""))
    span.set_attribute("airflow.task_id", os.getenv("AIRFLOW_CTX_TASK_ID", ""))
    span.set_attribute(
        "airflow.run_id",
        os.getenv("AIRFLOW_CTX_DAG_RUN_ID") or os.getenv("AIRFLOW_CTX_RUN_ID", ""),
    )
    span.set_attribute("airflow.try_number", os.getenv("AIRFLOW_CTX_TRY_NUMBER", ""))
    span.set_attribute("airflow.map_index", os.getenv("AIRFLOW_CTX_MAP_INDEX", ""))
    span.set_attribute(
        "airflow.logical_date",
        os.getenv("AIRFLOW_CTX_LOGICAL_DATE")
        or os.getenv("AIRFLOW_CTX_EXECUTION_DATE", ""),
    )


class StravaPipeline:
    """
    Main pipeline orchestrator for Strava data extraction.

    Handles pipeline initialization, execution, error handling,
    and request correlation via trace IDs.
    """

    def __init__(
        self,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        trace_id: Optional[str] = None,
    ):
        """
        Initialize Strava pipeline.

        Args:
            start_date: ISO date string for start of data range.
            end_date: ISO date string for end of data range.
            trace_id: Optional trace ID for request tracking.

        Raises:
            ValidationError: If dates are invalid.
        """
        # Validate inputs
        validate_date_string(start_date, "start_date")
        validate_date_string(end_date, "end_date")
        validate_date_range(start_date, end_date)

        self.settings = get_settings()
        self.start_date = start_date
        self.end_date = end_date
        self.trace_id = trace_id

    def _create_pipeline(self) -> dlt.Pipeline:
        """
        Create and configure dlt pipeline.

        Returns:
            Configured dlt.Pipeline instance.
        """
        import os

        # Get database path from environment variable or use default
        db_path = os.getenv("DUCKDB_PATH", "/opt/airflow/data/strava_datastack.duckdb")

        pipeline = dlt.pipeline(
            pipeline_name=self.settings.pipeline.name,
            destination=dlt.destinations.duckdb(credentials=db_path),
            dataset_name=self.settings.pipeline.dataset_name,
            progress=self.settings.pipeline.progress,
        )

        logger.info(
            f"DLT pipeline created: {pipeline.pipeline_name} -> "
            f"{pipeline.destination}/{self.settings.pipeline.dataset_name} (db_path={db_path})"
        )

        return pipeline

    def run(self) -> LoadInfo:
        """
        Execute the pipeline.

        Returns:
            Load info from dlt.

        Raises:
            PipelineError: If pipeline execution fails.
        """
        start_time = datetime.utcnow()
        tracer = trace.get_tracer(__name__)

        with tracer.start_as_current_span("strava.pipeline.run") as span:
            span.set_attribute("strava.start_date", self.start_date or "")
            span.set_attribute("strava.end_date", self.end_date or "")
            span.set_attribute("strava.pipeline_name", self.settings.pipeline.name)
            span.set_attribute("dlt.pipeline_name", self.settings.pipeline.name)
            span.set_attribute("dlt.dataset_name", self.settings.pipeline.dataset_name)
            span.set_attribute("dlt.destination", self.settings.pipeline.destination)
            _set_airflow_span_attributes(span)

            os.environ["DLT_PIPELINE_NAME"] = self.settings.pipeline.name
            os.environ["DLT_DATASET_NAME"] = self.settings.pipeline.dataset_name
            os.environ["DLT_DESTINATION"] = self.settings.pipeline.destination

            trace_id = format(span.get_span_context().trace_id, "032x")
            set_trace_id(trace_id)

            logger.info(
                f"Starting pipeline execution (trace_id={trace_id}, "
                f"start_date={self.start_date}, end_date={self.end_date})"
            )

            try:
                with tracer.start_as_current_span("strava.pipeline.create"):
                    pipeline = self._create_pipeline()

                with tracer.start_as_current_span("strava.pipeline.execute"):
                    source = strava_source(
                        start_date=self.start_date, end_date=self.end_date
                    )

                    logger.info("Executing pipeline run...")
                    load_info = pipeline.run(source)

                duration = (datetime.utcnow() - start_time).total_seconds()
                logger.info(f"Pipeline completed successfully in {duration:.2f}s")

                load_id = getattr(load_info, "load_id", None)
                if not load_id:
                    load_ids = getattr(load_info, "load_ids", None)
                    if isinstance(load_ids, (list, tuple)) and load_ids:
                        load_id = load_ids[0]
                if load_id:
                    span.set_attribute("dlt.load_id", str(load_id))
                    os.environ["DLT_LOAD_ID"] = str(load_id)

                return load_info

            except RateLimitExceededError:
                duration = (datetime.utcnow() - start_time).total_seconds()
                logger.warning(
                    f"Pipeline stopped after {duration:.2f}s due to rate limiting"
                )
                span.set_status(Status(StatusCode.ERROR, "rate_limited"))
                raise

            except Exception as e:
                duration = (datetime.utcnow() - start_time).total_seconds()
                logger.error(f"Pipeline failed after {duration:.2f}s: {e}", exc_info=True)
                span.set_status(Status(StatusCode.ERROR, str(e)))
                raise PipelineError(f"Pipeline execution failed: {e}") from e


def run_pipeline(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    configure_logging: bool = True,
) -> LoadInfo:
    """
    Convenience function to run the pipeline.

    Args:
        start_date: ISO date string for start of data range.
        end_date: ISO date string for end of data range.

    Returns:
        Load info from pipeline execution.

    Raises:
        PipelineError: If pipeline execution fails.
    """
    settings = get_settings()
    traceparent = os.getenv("STRAVA_TRACEPARENT") or os.getenv("TRACEPARENT")
    token = attach_trace_context(traceparent)
    try:
        if configure_logging:
            telemetry_handlers = setup_telemetry(
                TelemetryConfig(
                    enabled=settings.telemetry.enabled,
                    endpoint=settings.telemetry.endpoint,
                    service_name=settings.telemetry.service_name,
                    service_namespace=settings.telemetry.service_namespace,
                    environment=settings.environment,
                    enable_traces=settings.telemetry.enable_traces,
                    enable_logs=settings.telemetry.enable_logs,
                )
            )
            setup_logging(
                level=settings.logging.level,
                format_type=settings.logging.format,
                log_file=settings.logging.log_file,
                include_trace_id=settings.logging.include_trace_id,
                extra_handlers=telemetry_handlers,
            )

        # Create and run pipeline
        pipeline = StravaPipeline(start_date=start_date, end_date=end_date)
        return pipeline.run()
    finally:
        detach_trace_context(token)
