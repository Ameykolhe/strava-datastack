"""Rate limit state persistence for resumable rate limiting."""

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

from ..config.settings import get_settings
from ..utils.logging import get_logger

logger = get_logger(__name__)

DEFAULT_STATE_FILE = ".rate_limit_state.json"


@dataclass
class RateLimitState:
    """State tracking for rate limit handling."""

    # Request tracking
    total_requests_today: int = 0
    requests_since_last_429: int = 0

    # Timestamps
    day_start: Optional[str] = None  # ISO format
    last_429_time: Optional[str] = None  # ISO format
    resume_after: Optional[str] = None  # ISO format - when to resume

    # Retry tracking for current request
    current_request_retries: int = 0
    current_request_url: Optional[str] = None

    # Pipeline state for resumption
    last_successful_activity_id: Optional[int] = None
    last_successful_resource: Optional[str] = None
    pipeline_state: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        """Convert state to dictionary."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict) -> "RateLimitState":
        """Create state from dictionary."""
        return cls(**{k: v for k, v in data.items() if k in cls.__dataclass_fields__})


class RateLimitStateManager:
    """Manages persistence of rate limit state."""

    def __init__(self, state_file: Optional[str] = None):
        """
        Initialize state manager.

        Args:
            state_file: Path to state file. Defaults from config or .rate_limit_state.json
        """
        settings = get_settings()
        if state_file:
            self._state_file = Path(state_file)
        elif settings.rate_limiting.state_file:
            self._state_file = Path(settings.rate_limiting.state_file)
        else:
            self._state_file = Path(DEFAULT_STATE_FILE)

        self._state: Optional[RateLimitState] = None
        logger.debug(f"State manager initialized with file: {self._state_file}")

    @property
    def state(self) -> RateLimitState:
        """Get current state, loading from file if needed."""
        if self._state is None:
            self._state = self._load_state()
        return self._state

    def _load_state(self) -> RateLimitState:
        """Load state from file or create new state."""
        if self._state_file.exists():
            try:
                with open(self._state_file) as f:
                    data = json.load(f)
                state = RateLimitState.from_dict(data)
                logger.info(f"Loaded rate limit state from {self._state_file}")

                # Check if we need to reset daily counter
                if state.day_start:
                    day_start = datetime.fromisoformat(state.day_start)
                    if day_start.date() < datetime.now().date():
                        logger.info("New day detected, resetting daily request counter")
                        state.total_requests_today = 0
                        state.day_start = datetime.now().isoformat()

                return state
            except Exception as e:
                logger.warning(f"Failed to load state file: {e}. Starting fresh.")

        return RateLimitState(day_start=datetime.now().isoformat())

    def save_state(self) -> None:
        """Save current state to file."""
        if self._state is None:
            return

        try:
            with open(self._state_file, "w") as f:
                json.dump(self._state.to_dict(), f, indent=2)
            logger.debug(f"Saved rate limit state to {self._state_file}")
        except Exception as e:
            logger.error(f"Failed to save state file: {e}")

    def record_request(self) -> None:
        """Record a successful request."""
        self.state.total_requests_today += 1
        self.state.requests_since_last_429 += 1
        self.state.current_request_retries = 0
        self.state.current_request_url = None
        self.save_state()

    def record_429(self, request_url: str) -> None:
        """
        Record a 429 rate limit response.

        Args:
            request_url: URL of the request that got rate limited
        """
        now = datetime.now()
        self.state.last_429_time = now.isoformat()
        self.state.requests_since_last_429 = 0

        if self.state.current_request_url == request_url:
            self.state.current_request_retries += 1
        else:
            self.state.current_request_url = request_url
            self.state.current_request_retries = 1

        self.save_state()

    def set_resume_time(self, resume_after: datetime) -> None:
        """
        Set the time after which the pipeline should resume.

        Args:
            resume_after: DateTime when to resume
        """
        self.state.resume_after = resume_after.isoformat()
        self.save_state()

    def clear_resume_time(self) -> None:
        """Clear the resume time after successful resumption."""
        self.state.resume_after = None
        self.state.current_request_retries = 0
        self.state.current_request_url = None
        self.save_state()

    def save_pipeline_state(
        self,
        last_activity_id: Optional[int] = None,
        last_resource: Optional[str] = None,
        additional_state: Optional[dict] = None,
    ) -> None:
        """
        Save pipeline state for resumption after daily limit.

        Args:
            last_activity_id: ID of the last successfully processed activity
            last_resource: Name of the last resource being processed
            additional_state: Any additional state to preserve
        """
        if last_activity_id is not None:
            self.state.last_successful_activity_id = last_activity_id
        if last_resource is not None:
            self.state.last_successful_resource = last_resource
        if additional_state is not None:
            self.state.pipeline_state.update(additional_state)
        self.save_state()
        logger.info(
            f"Saved pipeline state: activity_id={last_activity_id}, "
            f"resource={last_resource}"
        )

    def get_resume_info(self) -> Optional[dict]:
        """
        Get information needed to resume pipeline.

        Returns:
            Dict with resume info or None if no resume needed
        """
        if self.state.resume_after:
            resume_time = datetime.fromisoformat(self.state.resume_after)
            if datetime.now() < resume_time:
                return {
                    "resume_after": resume_time,
                    "last_activity_id": self.state.last_successful_activity_id,
                    "last_resource": self.state.last_successful_resource,
                    "pipeline_state": self.state.pipeline_state,
                }
        return None

    def should_wait_for_resume(self) -> tuple[bool, Optional[datetime]]:
        """
        Check if we should wait before resuming.

        Returns:
            Tuple of (should_wait, resume_time)
        """
        if self.state.resume_after:
            resume_time = datetime.fromisoformat(self.state.resume_after)
            if datetime.now() < resume_time:
                return True, resume_time
        return False, None

    def reset(self) -> None:
        """Reset all state."""
        self._state = RateLimitState(day_start=datetime.now().isoformat())
        self.save_state()
        logger.info("Rate limit state reset")

    def delete_state_file(self) -> None:
        """Delete the state file."""
        if self._state_file.exists():
            self._state_file.unlink()
            logger.info(f"Deleted state file: {self._state_file}")
        self._state = None
