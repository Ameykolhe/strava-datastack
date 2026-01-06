"""Pytest fixtures and configuration for Strava extract tests."""

from datetime import timedelta
from pathlib import Path
from typing import Generator
from unittest.mock import Mock, patch

import pytest

from strava_extract.client.rate_limiter import RateLimiter
from strava_extract.config.settings import Settings, StravaCredentials


@pytest.fixture
def test_config() -> Settings:
    """
    Provide test configuration.

    Returns:
        Settings instance with test values.
    """
    config_data = {
        "api": {
            "base_url": "https://api.test.com/",
            "timeout_seconds": 10,
            "retry_attempts": 2,
        },
        "rate_limiting": {
            "max_requests": 5,
            "period_minutes": 1,
            "show_progress_bar": False,
        },
        "pagination": {
            "default_page_size": 50,
        },
        "pipeline": {
            "name": "test_pipeline",
            "destination": "duckdb",
            "dataset_name": "test_data",
        },
        "logging": {
            "level": "DEBUG",
            "format": "text",
        },
    }
    return Settings(**config_data)


@pytest.fixture
def test_credentials() -> StravaCredentials:
    """
    Provide test credentials.

    Returns:
        StravaCredentials instance with test values.
    """
    with patch.dict(
        "os.environ",
        {
            "STRAVA_CLIENT_ID": "test_client_id",
            "STRAVA_CLIENT_SECRET": "test_secret",
            "STRAVA_REFRESH_TOKEN": "test_refresh_token",
        },
    ):
        return StravaCredentials()


@pytest.fixture
def rate_limiter() -> RateLimiter:
    """
    Provide rate limiter for testing.

    Returns:
        RateLimiter instance with test settings.
    """
    return RateLimiter(max_requests=5, period=timedelta(seconds=1), show_progress=False)


@pytest.fixture
def mock_strava_api() -> Generator:
    """
    Mock Strava API responses.

    Yields:
        Mock session object.
    """
    with patch("requests.Session") as mock_session:
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "activities": [
                {
                    "id": 1,
                    "name": "Morning Run",
                    "type": "Run",
                    "distance": 5000,
                    "start_date": "2024-01-01T08:00:00Z",
                },
                {
                    "id": 2,
                    "name": "Evening Ride",
                    "type": "Ride",
                    "distance": 20000,
                    "start_date": "2024-01-02T18:00:00Z",
                },
            ]
        }
        mock_session.return_value.get.return_value = mock_response
        yield mock_session


@pytest.fixture
def sample_activities():
    """
    Provide sample activity data.

    Returns:
        List of sample activity dictionaries.
    """
    return [
        {
            "id": 1,
            "name": "Morning Run",
            "type": "Run",
            "distance": 5000,
            "start_date": "2024-01-01T08:00:00Z",
            "moving_time": 1800,
            "total_elevation_gain": 50,
        },
        {
            "id": 2,
            "name": "Evening Ride",
            "type": "Ride",
            "distance": 20000,
            "start_date": "2024-01-02T18:00:00Z",
            "moving_time": 3600,
            "total_elevation_gain": 200,
        },
        {
            "id": 3,
            "name": "Weekend Hike",
            "type": "Hike",
            "distance": 8000,
            "start_date": "2024-01-03T10:00:00Z",
            "moving_time": 7200,
            "total_elevation_gain": 500,
        },
    ]


@pytest.fixture(autouse=True)
def reset_settings():
    """
    Reset global settings between tests.

    This fixture automatically runs before each test to ensure
    settings don't leak between tests.
    """
    from strava_extract.config.settings import reset_settings

    reset_settings()
    yield
    reset_settings()


@pytest.fixture
def temp_config_file(tmp_path: Path) -> Path:
    """
    Create a temporary config file for testing.

    Args:
        tmp_path: Pytest tmp_path fixture.

    Returns:
        Path to temporary config file.
    """
    config_content = """
api:
  base_url: "https://test-api.com/"
  timeout_seconds: 5

rate_limiting:
  max_requests: 10
  period_minutes: 1
  show_progress_bar: false

logging:
  level: "DEBUG"
  format: "text"
"""
    config_file = tmp_path / "test_config.yaml"
    config_file.write_text(config_content)
    return config_file
