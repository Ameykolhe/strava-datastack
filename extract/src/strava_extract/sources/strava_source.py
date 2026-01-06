"""DLT source definition for Strava API extraction."""

from pathlib import Path
from typing import Optional

import dlt
import yaml
from dlt.common.pendulum import pendulum
from dlt.sources.rest_api import RESTAPIConfig, rest_api_resources

from ..client.paginator import RateLimitedPaginator
from ..client.rate_limiter import RateLimiter
from ..config.settings import get_settings
from ..utils.exceptions import ConfigurationError
from ..utils.logging import get_logger

logger = get_logger(__name__)

# Shared rate limiter instance (singleton per process)
_rate_limiter: Optional[RateLimiter] = None


def get_rate_limiter() -> RateLimiter:
    """
    Get or create singleton rate limiter instance.

    Returns:
        RateLimiter instance.
    """
    global _rate_limiter
    if _rate_limiter is None:
        _rate_limiter = RateLimiter()
    return _rate_limiter


def load_resource_config() -> list:
    """
    Load resource definitions from YAML file.

    Returns:
        List of resource configurations.

    Raises:
        ConfigurationError: If resource config file cannot be loaded.
    """
    config_path = (
        Path(__file__).parent.parent.parent.parent / "config" / "resources.yaml"
    )

    if not config_path.exists():
        raise ConfigurationError(f"Resource config not found: {config_path}")

    try:
        with open(config_path) as f:
            data = yaml.safe_load(f)
    except Exception as e:
        raise ConfigurationError(
            f"Failed to load resource config from {config_path}: {e}"
        ) from e

    return data.get("resources", [])


def build_rest_api_config(
    start_date: Optional[str], end_date: Optional[str]
) -> RESTAPIConfig:
    """
    Build REST API configuration from resource definitions.

    Args:
        start_date: ISO date string for incremental start.
        end_date: ISO date string for incremental end.

    Returns:
        REST API configuration for dlt.
    """
    settings = get_settings()
    rate_limiter = get_rate_limiter()

    # Load base resource configurations
    resource_configs = load_resource_config()

    # Determine incremental dates
    load_from_date = (
        pendulum.parse(start_date).to_iso8601_string()  # type: ignore[union-attr]
        if start_date
        else dlt.current.source_state().setdefault(
            "last_value",
            pendulum.today()
            .subtract(days=settings.incremental.default_lookback_days)
            .to_iso8601_string(),
        )
    )

    load_until_date = (
        pendulum.parse(end_date).to_iso8601_string()  # type: ignore[union-attr]
        if end_date
        else None
    )

    logger.info(f"Incremental load: from={load_from_date}, until={load_until_date}")

    # Build resources with runtime configuration
    resources = []
    for res_config in resource_configs:
        resource = {
            "name": res_config["name"],
            "primary_key": res_config["primary_key"],
            "endpoint": {
                "path": res_config["endpoint"]["path"],
                "params": res_config["endpoint"].get("params", {}).copy(),
                "paginator": RateLimitedPaginator(
                    rate_limiter=rate_limiter,
                    resource_name=res_config["name"],
                    base_page=settings.pagination.base_page,
                    total_path=None,
                    maximum_page=res_config["endpoint"]
                    .get("pagination", {})
                    .get("maximum_page"),
                ),
            },
        }

        # Add optional fields
        if "write_disposition" in res_config:
            resource["write_disposition"] = res_config["write_disposition"]

        if "max_table_nesting" in res_config:
            resource["max_table_nesting"] = res_config["max_table_nesting"]

        if "include_from_parent" in res_config:
            resource["include_from_parent"] = res_config["include_from_parent"]

        if "response_actions" in res_config["endpoint"]:
            resource["endpoint"]["response_actions"] = res_config["endpoint"][
                "response_actions"
            ]

        # Add incremental configuration if enabled
        if res_config.get("incremental", {}).get("enabled"):
            inc_config = res_config["incremental"]
            resource["endpoint"]["incremental"] = {
                "start_param": inc_config["start_param"],
                "end_param": inc_config["end_param"],
                "cursor_path": inc_config["cursor_path"],
                "initial_value": load_from_date,
                "end_value": load_until_date,
                "convert": lambda ts: (
                    None
                    if ts is None
                    else int(pendulum.parse(ts).timestamp())  # type: ignore[union-attr]
                ),
            }

        resources.append(resource)

    # Import and create auth instance from environment variables
    from ..auth.oauth import get_auth

    auth = get_auth()

    # Build full config
    config: RESTAPIConfig = {
        "client": {"base_url": settings.api.base_url, "auth": auth},
        "resource_defaults": {
            "primary_key": "id",
            "write_disposition": "merge",
            "endpoint": {
                "params": {
                    "per_page": settings.pagination.default_page_size,
                },
            },
        },
        "resources": resources,  # type: ignore[typeddict-item]
    }

    return config


@dlt.source(name="strava")
def strava_source(start_date: Optional[str] = None, end_date: Optional[str] = None):
    """
    Strava DLT source for extracting activity data.

    This source extracts:
    - activities: Activity metadata
    - activity_streams: Time-series data (heart rate, speed, etc.)
    - activity_zones: Heart rate/power zones

    Args:
        start_date: ISO date string for start of data range (e.g., '2024-01-01').
                   If None, uses incremental state or default lookback period.
        end_date: ISO date string for end of data range (e.g., '2024-12-31').
                 If None, loads data up to current time.

    Yields:
        DLT resources for Strava data.
    """
    logger.info(f"Building Strava source (start={start_date}, end={end_date})")

    config = build_rest_api_config(start_date, end_date)

    yield from rest_api_resources(config)
