"""CLI entry point for Strava extract pipeline."""

import argparse
import sys
from pathlib import Path

# Load .env file early
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent.parent / ".env")

from .client.rate_limiter import RateLimitExceededError  # noqa: E402
from .config.settings import get_settings  # noqa: E402
from .pipeline import run_pipeline  # noqa: E402
from .utils.exceptions import StravaExtractError  # noqa: E402
from .utils.logging import get_logger, setup_logging  # noqa: E402
from .utils.telemetry import TelemetryConfig, setup_telemetry  # noqa: E402


def parse_args() -> argparse.Namespace:
    """
    Parse command line arguments.

    Returns:
        Parsed arguments.
    """
    parser = argparse.ArgumentParser(
        description="Strava data extraction pipeline using DLT",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Load last 30 days (default)
  python -m strava_extract

  # Load from specific start date
  python -m strava_extract --start-date 2024-01-01

  # Load specific date range
  python -m strava_extract --start-date 2024-01-01 --end-date 2024-07-01

  # Override log level
  python -m strava_extract --log-level DEBUG

  # Use custom config file
  STRAVA_CONFIG_PATH=/path/to/config.yaml python -m strava_extract
        """,
    )

    parser.add_argument(
        "--start-date",
        type=str,
        default=None,
        help="Start date for data extraction (ISO format: YYYY-MM-DD)",
    )

    parser.add_argument(
        "--end-date",
        type=str,
        default=None,
        help="End date for data extraction (ISO format: YYYY-MM-DD)",
    )

    parser.add_argument(
        "--config",
        type=str,
        default=None,
        help="Path to configuration file (overrides STRAVA_CONFIG_PATH env var)",
    )

    parser.add_argument(
        "--log-level",
        type=str,
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        default="INFO",
        help="Override log level from config",
    )

    return parser.parse_args()


def main() -> int:
    """
    Main entry point for CLI.

    Returns:
        Exit code (0 for success, non-zero for failure).
    """
    args = parse_args()

    # Override config path if provided
    if args.config:
        import os

        os.environ["STRAVA_CONFIG_PATH"] = args.config

    try:
        settings = get_settings()
        log_level = args.log_level or settings.logging.level
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
            level=log_level,
            format_type=settings.logging.format,
            log_file=settings.logging.log_file,
            include_trace_id=settings.logging.include_trace_id,
            extra_handlers=telemetry_handlers,
        )

        logger = get_logger(__name__)

        logger.info("Starting Strava extraction pipeline")

        # Run pipeline
        load_info = run_pipeline(
            start_date=args.start_date, end_date=args.end_date, configure_logging=False
        )

        # Print summary
        print("\n" + "=" * 80)
        print("Pipeline completed successfully!")
        print("=" * 80)
        print(load_info)
        print("=" * 80 + "\n")

        return 0

    except RateLimitExceededError as e:
        # Special handling for rate limit exceeded - save state and inform user
        try:
            logger = get_logger(__name__)
            logger.warning(f"Rate limit exceeded: {e}")
        except Exception:
            pass

        print("\n" + "=" * 80, file=sys.stderr)
        print("RATE LIMIT EXCEEDED - Daily limit reached (1000 requests/day)", file=sys.stderr)
        print("=" * 80, file=sys.stderr)
        print(f"\nPipeline state has been saved for resumption.", file=sys.stderr)
        print(f"Resume after: {e.resume_after.isoformat()}", file=sys.stderr)
        print("\nRun the pipeline again after the specified time to continue.\n", file=sys.stderr)
        return 2  # Special exit code for rate limit

    except StravaExtractError as e:
        # Setup basic logging if it failed during initialization
        try:
            logger = get_logger(__name__)
            logger.error(f"Pipeline failed: {e}", exc_info=True)
        except Exception:
            pass

        print(f"\nERROR: {e}\n", file=sys.stderr)
        return 1

    except KeyboardInterrupt:
        try:
            logger = get_logger(__name__)
            logger.warning("Pipeline interrupted by user")
        except Exception:
            pass

        print("\nPipeline interrupted by user\n", file=sys.stderr)
        return 130  # Standard exit code for SIGINT

    except Exception as e:
        try:
            logger = get_logger(__name__)
            logger.error(f"Unexpected error: {e}", exc_info=True)
        except Exception:
            pass

        print(f"\nUNEXPECTED ERROR: {e}\n", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
