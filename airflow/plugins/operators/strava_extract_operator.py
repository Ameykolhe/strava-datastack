"""Custom operator for Strava data extraction."""

import logging
import os
from typing import Optional

import structlog
from airflow.models import BaseOperator, Variable
from opentelemetry import trace
from opentelemetry.propagate import inject


class StravaExtractOperator(BaseOperator):
    """
    Operator to run Strava data extraction pipeline.

    This operator:
    1. Retrieves Strava credentials from Airflow Variables
    2. Sets environment variables for dlt
    3. Calls strava_extract.run_pipeline()
    4. Returns load statistics

    :param extract_start_date: Start date for extraction (YYYY-MM-DD format)
    :param extract_end_date: End date for extraction (YYYY-MM-DD format)
    """

    template_fields = ["extract_start_date", "extract_end_date"]
    ui_color = "#ff5a00"  # Strava brand color

    def __init__(
        self,
        extract_start_date: Optional[str] = None,
        extract_end_date: Optional[str] = None,
        **kwargs
    ):
        super().__init__(**kwargs)
        self.extract_start_date = extract_start_date
        self.extract_end_date = extract_end_date

    def execute(self, context):
        """Execute the extraction pipeline."""
        # Handle Jinja2 templating converting None to "None" string
        start_date = None if self.extract_start_date in (None, "None", "") else self.extract_start_date
        end_date = None if self.extract_end_date in (None, "None", "") else self.extract_end_date

        self.log.info(
            f"Starting Strava extraction: {start_date or 'last 30 days'} to {end_date or 'today'}"
        )

        # Retrieve credentials from Airflow Variables
        try:
            client_id = Variable.get("STRAVA_CLIENT_ID")
            client_secret = Variable.get("STRAVA_CLIENT_SECRET")
            refresh_token = Variable.get("STRAVA_REFRESH_TOKEN")
        except KeyError as e:
            raise ValueError(
                f"Missing required Airflow Variable: {e}. "
                "Please set STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET, "
                "and STRAVA_REFRESH_TOKEN variables via Airflow UI or CLI."
            ) from e

        # Set environment variables for dlt
        os.environ["CREDENTIALS__CLIENT_ID"] = client_id
        os.environ["CREDENTIALS__CLIENT_SECRET"] = client_secret
        os.environ["CREDENTIALS__REFRESH_TOKEN"] = refresh_token

        try:
            from strava_extract import run_pipeline
            from strava_extract.config.settings import get_settings
            from strava_extract.utils.telemetry import (
                TelemetryConfig,
                attach_trace_context,
                detach_trace_context,
                setup_telemetry,
            )

            settings = get_settings()
            os.environ["DLT_PIPELINE_NAME"] = settings.pipeline.name
            os.environ["DLT_DATASET_NAME"] = settings.pipeline.dataset_name
            os.environ["DLT_DESTINATION"] = settings.pipeline.destination

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
            root_logger = logging.getLogger()
            for handler in telemetry_handlers:
                if not any(isinstance(existing, type(handler)) for existing in root_logger.handlers):
                    root_logger.addHandler(handler)

            self.log.info("Running Strava extract pipeline...")
            task_instance = context.get("ti")
            carrier = {}
            if task_instance and isinstance(getattr(task_instance, "context_carrier", None), dict):
                carrier = task_instance.context_carrier
            traceparent = carrier.get("traceparent") or os.getenv("TRACEPARENT")
            token = None
            if traceparent and not trace.get_current_span().get_span_context().is_valid:
                token = attach_trace_context(traceparent)
            tracer = trace.get_tracer(__name__)
            try:
                with tracer.start_as_current_span("strava.extract.task") as span:
                    dag_run = context.get("dag_run")
                    logical_date = context.get("logical_date")
                    span.set_attribute("airflow.dag_id", context["dag"].dag_id)
                    span.set_attribute("airflow.task_id", context["task"].task_id)
                    span.set_attribute("airflow.run_id", dag_run.run_id if dag_run else "")
                    span.set_attribute(
                        "airflow.try_number",
                        task_instance.try_number if task_instance else 0,
                    )
                    span.set_attribute(
                        "airflow.map_index",
                        task_instance.map_index if task_instance else -1,
                    )
                    span.set_attribute(
                        "airflow.logical_date",
                        logical_date.isoformat() if logical_date else "",
                    )
                    span.set_attribute("dlt.pipeline_name", settings.pipeline.name)
                    span.set_attribute("dlt.dataset_name", settings.pipeline.dataset_name)
                    span.set_attribute("dlt.destination", settings.pipeline.destination)

                    downstream: dict[str, str] = {}
                    inject(downstream)
                    injected_traceparent = downstream.get("traceparent") or traceparent
                    if injected_traceparent:
                        os.environ["STRAVA_TRACEPARENT"] = injected_traceparent
                        os.environ["TRACEPARENT"] = injected_traceparent

                    load_info = run_pipeline(
                        start_date=start_date,
                        end_date=end_date,
                        configure_logging=False,
                    )
            finally:
                detach_trace_context(token)

            load_id = getattr(load_info, "load_id", None)
            if not load_id:
                load_ids = getattr(load_info, "load_ids", None)
                if isinstance(load_ids, (list, tuple)) and load_ids:
                    load_id = load_ids[0]
            if load_id:
                os.environ["DLT_LOAD_ID"] = str(load_id)
                structlog.contextvars.bind_contextvars(dlt_load_id=str(load_id))

            # Log statistics
            self.log.info(f"Pipeline completed successfully: {load_info}")

            # Extract schema lineage from dlt pipeline
            lineage = {"tables": {}}
            pipeline = load_info.pipeline
            if pipeline and pipeline.default_schema:
                schema = pipeline.default_schema
                for table_name, table in schema.tables.items():
                    if table_name.startswith("_dlt"):
                        continue
                    lineage["tables"][table_name] = {
                        "columns": [
                            {
                                "name": col_name,
                                "data_type": col.get("data_type"),
                                "nullable": col.get("nullable", True),
                            }
                            for col_name, col in table.get("columns", {}).items()
                        ],
                        "resource": table.get("resource"),
                        "write_disposition": table.get("write_disposition"),
                        "parent": table.get("parent"),
                    }

            # Return statistics for XCom
            return {
                "start_date": start_date,
                "end_date": end_date,
                "load_info": str(load_info),
                "lineage": lineage,
                "destination": load_info.destination_name,
                "dataset": load_info.dataset_name,
            }

        except Exception as e:
            self.log.error(f"Pipeline failed: {e}")
            raise
        finally:
            # Clean up environment variables
            for key in [
                "CREDENTIALS__CLIENT_ID",
                "CREDENTIALS__CLIENT_SECRET",
                "CREDENTIALS__REFRESH_TOKEN",
                "STRAVA_TRACEPARENT",
                "TRACEPARENT",
                "DLT_PIPELINE_NAME",
                "DLT_DATASET_NAME",
                "DLT_DESTINATION",
                "DLT_LOAD_ID",
            ]:
                os.environ.pop(key, None)
