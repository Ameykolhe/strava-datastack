"""Custom operator for Strava data extraction."""

import os
from typing import Optional

import sentry_sdk
from airflow.models import BaseOperator, Variable


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
        trace_ctx = context.get("ti").xcom_pull(task_ids="start_trace") if context.get("ti") else None
        if isinstance(trace_ctx, dict):
            if trace_ctx.get("sentry_trace"):
                os.environ["SENTRY_TRACE"] = trace_ctx["sentry_trace"]
            if trace_ctx.get("sentry_baggage"):
                os.environ["SENTRY_BAGGAGE"] = trace_ctx["sentry_baggage"]

        try:
            from strava_extract.utils.sentry import init_sentry_from_settings
        except ModuleNotFoundError:
            init_sentry_from_settings = None

        if init_sentry_from_settings:
            sentry_enabled = init_sentry_from_settings()
            if sentry_enabled:
                self.log.info("Sentry observability enabled for Airflow task")

        # Handle Jinja2 templating converting None to "None" string
        start_date = None if self.extract_start_date in (None, "None", "") else self.extract_start_date
        end_date = None if self.extract_end_date in (None, "None", "") else self.extract_end_date

        # Extract Airflow context for Sentry
        dag_id = context.get("dag").dag_id if context.get("dag") else None
        task_id = context.get("task_instance").task_id if context.get("task_instance") else None
        run_id = context.get("run_id")
        execution_date = str(context.get("execution_date")) if context.get("execution_date") else None

        # Set Sentry context with Airflow metadata
        with sentry_sdk.configure_scope() as scope:
            scope.set_tag("dag_id", dag_id)
            scope.set_tag("task_id", task_id)
            scope.set_tag("run_id", run_id)
            scope.set_context(
                "airflow",
                {
                    "dag_id": dag_id,
                    "task_id": task_id,
                    "run_id": run_id,
                    "execution_date": execution_date,
                    "start_date": start_date,
                    "end_date": end_date,
                },
            )

        self.log.info(
            f"Starting Strava extraction: {start_date or 'last 30 days'} to {end_date or 'today'}"
        )

        # Retrieve credentials from Airflow Variables
        try:
            client_id = Variable.get("STRAVA_CLIENT_ID")
            client_secret = Variable.get("STRAVA_CLIENT_SECRET")
            refresh_token = Variable.get("STRAVA_REFRESH_TOKEN")
        except KeyError as e:
            sentry_sdk.capture_exception(e)
            raise ValueError(
                f"Missing required Airflow Variable: {e}. "
                "Please set STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET, "
                "and STRAVA_REFRESH_TOKEN variables via Airflow UI or CLI."
            ) from e

        # Set environment variables for dlt
        os.environ["CREDENTIALS__CLIENT_ID"] = client_id
        os.environ["CREDENTIALS__CLIENT_SECRET"] = client_secret
        os.environ["CREDENTIALS__REFRESH_TOKEN"] = refresh_token

        # Import and run pipeline with Sentry transaction
        trace_headers = {}
        if os.getenv("SENTRY_TRACE"):
            trace_headers["sentry-trace"] = os.getenv("SENTRY_TRACE")
        if os.getenv("SENTRY_BAGGAGE"):
            trace_headers["baggage"] = os.getenv("SENTRY_BAGGAGE")

        if trace_headers:
            transaction = sentry_sdk.continue_trace(
                trace_headers,
                op="airflow.task",
                name=f"airflow.{dag_id}.{task_id}",
            )
        else:
            transaction = sentry_sdk.start_transaction(
                name=f"airflow.{dag_id}.{task_id}",
                op="airflow.task",
                description=f"Strava extraction: {start_date or 'default'} to {end_date or 'now'}",
            )

        with transaction:
            try:
                from strava_extract import run_pipeline

                self.log.info("Running Strava extract pipeline...")
                load_info = run_pipeline(
                    start_date=start_date,
                    end_date=end_date,
                )

                # Log statistics
                self.log.info(f"Pipeline completed successfully: {load_info}")

                # Set transaction status to OK
                transaction.set_status("ok")

                # Return statistics for XCom
                return {
                    "start_date": start_date,
                    "end_date": end_date,
                    "load_info": str(load_info),
                }

            except Exception as e:
                self.log.error(f"Pipeline failed: {e}")
                sentry_sdk.capture_exception(e)
                transaction.set_status("internal_error")
                raise
            finally:
                # Clean up environment variables
                for key in [
                    "CREDENTIALS__CLIENT_ID",
                    "CREDENTIALS__CLIENT_SECRET",
                    "CREDENTIALS__REFRESH_TOKEN",
                ]:
                    os.environ.pop(key, None)
