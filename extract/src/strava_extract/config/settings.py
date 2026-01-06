"""Type-safe configuration management using Pydantic."""

import yaml
from pathlib import Path
from typing import Optional, Literal
from pydantic import BaseModel, Field, SecretStr, field_validator
from pydantic_settings import BaseSettings

from ..utils.exceptions import ConfigurationError


class APIConfig(BaseModel):
    """API configuration settings."""
    base_url: str = "https://www.strava.com/api/v3/"
    version: str = "v3"
    timeout_seconds: int = 30
    retry_attempts: int = 3
    retry_backoff_factor: float = 2.0


class RateLimitConfig(BaseModel):
    """Rate limiting configuration settings."""
    max_requests: int = 95
    period_minutes: int = 15
    enable_rate_limiter: bool = True
    show_progress_bar: bool = True


class PaginationConfig(BaseModel):
    """Pagination configuration settings."""
    default_page_size: int = 200
    max_page_size: int = 200
    base_page: int = 1


class PipelineConfig(BaseModel):
    """DLT pipeline configuration settings."""
    name: str = "strava_datastack"
    destination: str = "duckdb"
    dataset_name: str = "strava_raw"
    progress: Literal["log", "enlighten", "alive_progress"] = "log"


class IncrementalConfig(BaseModel):
    """Incremental loading configuration settings."""
    default_lookback_days: int = 30
    cursor_field: str = "start_date"


class LoggingConfig(BaseModel):
    """Logging configuration settings."""
    level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
    format: Literal["json", "text"] = "text"
    log_file: Optional[str] = None
    include_trace_id: bool = True


class StravaCredentials(BaseSettings):
    """
    Strava OAuth credentials loaded from environment variables.

    These values should be set in .env file or as environment variables.
    """
    client_id: str = Field(..., description="Strava API client ID")
    client_secret: SecretStr = Field(..., description="Strava API client secret")
    refresh_token: SecretStr = Field(..., description="Strava OAuth refresh token")
    access_token_url: str = Field(
        default="https://www.strava.com/oauth/token",
        description="OAuth token URL"
    )

    model_config = {
        "env_prefix": "STRAVA_",
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


class Settings(BaseSettings):
    """
    Main application settings.

    Loads configuration from YAML file with environment variable overrides.
    """
    api: APIConfig = Field(default_factory=APIConfig)
    rate_limiting: RateLimitConfig = Field(default_factory=RateLimitConfig)
    pagination: PaginationConfig = Field(default_factory=PaginationConfig)
    pipeline: PipelineConfig = Field(default_factory=PipelineConfig)
    incremental: IncrementalConfig = Field(default_factory=IncrementalConfig)
    logging: LoggingConfig = Field(default_factory=LoggingConfig)

    environment: Literal["development", "staging", "production"] = Field(
        default="development",
        description="Deployment environment"
    )

    config_path: Optional[Path] = Field(
        default=None,
        description="Path to configuration file"
    )

    model_config = {
        "env_prefix": "STRAVA_",
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "env_nested_delimiter": "__",  # Allows STRAVA__API__BASE_URL
        "case_sensitive": False,
        "extra": "ignore",  # Ignore extra fields (like credentials)
    }

    @classmethod
    def from_yaml(cls, config_path: Optional[Path] = None) -> "Settings":
        """
        Load settings from YAML file with environment variable overrides.

        Args:
            config_path: Path to config YAML file. If None, uses default location.

        Returns:
            Settings instance with loaded configuration.

        Raises:
            ConfigurationError: If config file cannot be loaded.
        """
        if config_path is None:
            # Default to config/config.yaml relative to this file
            config_path = (
                Path(__file__).parent.parent.parent.parent / "config" / "config.yaml"
            )

        if not config_path.exists():
            raise ConfigurationError(
                f"Configuration file not found: {config_path}\n"
                f"Please create a config.yaml file or specify a valid path."
            )

        try:
            with open(config_path) as f:
                config_data = yaml.safe_load(f)
        except Exception as e:
            raise ConfigurationError(
                f"Failed to load configuration from {config_path}: {e}"
            ) from e

        if config_data is None:
            config_data = {}

        # Store the config path
        config_data["config_path"] = str(config_path)

        return cls(**config_data)


# Global settings instance (singleton pattern)
_settings: Optional[Settings] = None


def get_settings(config_path: Optional[Path] = None) -> Settings:
    """
    Get singleton settings instance.

    Args:
        config_path: Optional path to config file. Only used on first call.

    Returns:
        Settings instance.
    """
    global _settings
    if _settings is None:
        _settings = Settings.from_yaml(config_path)
    return _settings


def get_credentials() -> StravaCredentials:
    """
    Get Strava credentials from environment.

    Returns:
        StravaCredentials instance.

    Raises:
        ConfigurationError: If required credentials are missing.
    """
    try:
        return StravaCredentials()
    except Exception as e:
        raise ConfigurationError(
            f"Failed to load Strava credentials: {e}\n"
            f"Please ensure STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET, and "
            f"STRAVA_REFRESH_TOKEN are set in your .env file or environment."
        ) from e


def reset_settings() -> None:
    """Reset the global settings instance (useful for testing)."""
    global _settings
    _settings = None
