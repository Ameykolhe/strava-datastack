"""Main pipeline orchestration for Strava data extraction."""

from datetime import datetime
from typing import Optional

import dlt
from dlt.common.pipeline import LoadInfo

from .config.settings import get_settings
from .sources.strava_source import strava_source
from .utils.exceptions import PipelineError
from .utils.logging import get_logger, set_trace_id, setup_logging
from .utils.validators import validate_date_range, validate_date_string

logger = get_logger(__name__)


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
        self.trace_id = trace_id or set_trace_id()

        logger.info(
            f"Pipeline initialized with trace_id={self.trace_id}, "
            f"start_date={start_date}, end_date={end_date}"
        )

    def _create_pipeline(self) -> dlt.Pipeline:
        """
        Create and configure dlt pipeline.

        Returns:
            Configured dlt.Pipeline instance.
        """
        pipeline = dlt.pipeline(
            pipeline_name=self.settings.pipeline.name,
            destination=self.settings.pipeline.destination,
            dataset_name=self.settings.pipeline.dataset_name,
            progress=self.settings.pipeline.progress,
        )

        logger.info(
            f"DLT pipeline created: {pipeline.pipeline_name} -> "
            f"{pipeline.destination}/{self.settings.pipeline.dataset_name}"
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
        logger.info(f"Starting pipeline execution (trace_id={self.trace_id})")

        try:
            # Create pipeline
            pipeline = self._create_pipeline()

            # Create source
            source = strava_source(start_date=self.start_date, end_date=self.end_date)

            # Run pipeline
            logger.info("Executing pipeline run...")
            load_info = pipeline.run(source)

            # Log results
            duration = (datetime.utcnow() - start_time).total_seconds()
            logger.info(f"Pipeline completed successfully in {duration:.2f}s")

            return load_info

        except Exception as e:
            duration = (datetime.utcnow() - start_time).total_seconds()
            logger.error(f"Pipeline failed after {duration:.2f}s: {e}", exc_info=True)

            # Fail fast - raise immediately
            raise PipelineError(f"Pipeline execution failed: {e}") from e


def run_pipeline(
    start_date: Optional[str] = None, end_date: Optional[str] = None
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
    # Setup logging
    settings = get_settings()
    setup_logging(
        level=settings.logging.level,
        format_type=settings.logging.format,
        log_file=settings.logging.log_file,
    )

    # Create and run pipeline
    pipeline = StravaPipeline(start_date=start_date, end_date=end_date)
    return pipeline.run()
