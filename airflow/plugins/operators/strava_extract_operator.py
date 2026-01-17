"""Custom operator for Strava data extraction."""

import os
from typing import Optional

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

        # Import and run pipeline
        try:
            from strava_extract import run_pipeline

            self.log.info("Running Strava extract pipeline...")
            load_info = run_pipeline(
                start_date=start_date,
                end_date=end_date,
            )

            # Log statistics
            self.log.info(f"Pipeline completed successfully: {load_info}")

            # Return statistics for XCom
            return {
                "start_date": start_date,
                "end_date": end_date,
                "load_info": str(load_info),
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
            ]:
                os.environ.pop(key, None)
