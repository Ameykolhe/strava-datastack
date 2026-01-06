"""Custom exceptions for the Strava extract pipeline."""

from typing import Optional


class StravaExtractError(Exception):
    """Base exception for all Strava extract errors."""
    pass


class ConfigurationError(StravaExtractError):
    """Raised when there are configuration-related errors."""
    pass


class AuthenticationError(StravaExtractError):
    """Raised when authentication or authorization fails."""
    pass


class RateLimitError(StravaExtractError):
    """Raised when rate limiting errors occur."""
    pass


class APIError(StravaExtractError):
    """Raised when Strava API errors occur."""

    def __init__(self, message: str, status_code: Optional[int] = None):
        """
        Initialize API error.

        Args:
            message: Error message.
            status_code: HTTP status code if available.
        """
        super().__init__(message)
        self.status_code = status_code


class ValidationError(StravaExtractError):
    """Raised when input validation fails."""
    pass


class PipelineError(StravaExtractError):
    """Raised when pipeline execution fails."""
    pass
