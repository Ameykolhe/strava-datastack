"""CLI entry point for Strava extract pipeline."""

import argparse
import sys
from typing import Optional
from pathlib import Path

# Load .env file early
from dotenv import load_dotenv
load_dotenv(Path(__file__).parent.parent.parent / ".env")

from .pipeline import run_pipeline
from .utils.logging import setup_logging, get_logger
from .utils.exceptions import StravaExtractError
from .config.settings import get_settings

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
        """
    )

    parser.add_argument(
        "--start-date",
        type=str,
        default=None,
        help="Start date for data extraction (ISO format: YYYY-MM-DD)"
    )

    parser.add_argument(
        "--end-date",
        type=str,
        default=None,
        help="End date for data extraction (ISO format: YYYY-MM-DD)"
    )

    parser.add_argument(
        "--config",
        type=str,
        default=None,
        help="Path to configuration file (overrides STRAVA_CONFIG_PATH env var)"
    )

    parser.add_argument(
        "--log-level",
        type=str,
        choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
        default=None,
        help="Override log level from config"
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
        # Setup logging
        settings = get_settings()
        log_level = args.log_level or settings.logging.level
        setup_logging(
            level=log_level,
            format_type=settings.logging.format,
            log_file=settings.logging.log_file
        )

        logger = get_logger(__name__)
        logger.info("Starting Strava extraction pipeline")

        # Run pipeline
        load_info = run_pipeline(
            start_date=args.start_date,
            end_date=args.end_date
        )

        # Print summary
        print("\n" + "=" * 80)
        print("Pipeline completed successfully!")
        print("=" * 80)
        print(load_info)
        print("=" * 80 + "\n")

        return 0

    except StravaExtractError as e:
        # Setup basic logging if it failed during initialization
        try:
            logger = get_logger(__name__)
            logger.error(f"Pipeline failed: {e}", exc_info=True)
        except:
            pass

        print(f"\nERROR: {e}\n", file=sys.stderr)
        return 1

    except KeyboardInterrupt:
        try:
            logger = get_logger(__name__)
            logger.warning("Pipeline interrupted by user")
        except:
            pass

        print("\nPipeline interrupted by user\n", file=sys.stderr)
        return 130  # Standard exit code for SIGINT

    except Exception as e:
        try:
            logger = get_logger(__name__)
            logger.error(f"Unexpected error: {e}", exc_info=True)
        except:
            pass

        print(f"\nUNEXPECTED ERROR: {e}\n", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
