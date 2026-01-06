"""Input validation utilities for the Strava extract pipeline."""

from datetime import datetime
from typing import Optional

from .exceptions import ValidationError


def validate_date_string(date_str: Optional[str], field_name: str = "date") -> None:
    """
    Validate that a date string is in ISO format (YYYY-MM-DD).

    Args:
        date_str: Date string to validate. None is considered valid.
        field_name: Name of the field for error messages.

    Raises:
        ValidationError: If date string is invalid.
    """
    if date_str is None:
        return

    try:
        datetime.fromisoformat(date_str)
    except (ValueError, TypeError) as e:
        raise ValidationError(
            f"Invalid {field_name}: '{date_str}'. "
            f"Expected ISO format (YYYY-MM-DD). Error: {e}"
        ) from e


def validate_date_range(start_date: Optional[str], end_date: Optional[str]) -> None:
    """
    Validate that start_date is before end_date.

    Args:
        start_date: Start date string (ISO format).
        end_date: End date string (ISO format).

    Raises:
        ValidationError: If date range is invalid.
    """
    if start_date and end_date:
        try:
            start = datetime.fromisoformat(start_date)
            end = datetime.fromisoformat(end_date)

            if start >= end:
                raise ValidationError(
                    f"Invalid date range: start_date ({start_date}) "
                    f"must be before end_date ({end_date})"
                )
        except ValueError as e:
            raise ValidationError(f"Error validating date range: {e}") from e
