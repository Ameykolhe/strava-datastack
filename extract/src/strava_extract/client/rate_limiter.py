"""Reactive rate limiter for Strava API requests."""

import sys
import time
from datetime import datetime, timedelta
from threading import Lock
from typing import Optional

from tqdm import tqdm  # type: ignore[import-untyped]

from ..config.settings import get_settings
from ..utils.exceptions import RateLimitError
from ..utils.logging import get_logger
from .rate_limit_state import RateLimitStateManager

logger = get_logger(__name__)


class RateLimitExceededError(RateLimitError):
    """Raised when daily rate limit is exceeded and pipeline should stop."""

    def __init__(self, message: str, resume_after: datetime):
        super().__init__(message)
        self.resume_after = resume_after


class RateLimiter:
    """
    Reactive rate limiter for Strava API requests.

    Only sleeps when a 429 response is encountered:
    - First 429: Sleep for 15 minutes (short-term limit)
    - Second 429 on same request: Save state and wait 24 hours (daily limit)

    Strava rate limits:
    - 100 requests per 15 minutes
    - 1000 requests per day
    """

    def __init__(
        self,
        show_progress: Optional[bool] = None,
        state_file: Optional[str] = None,
    ):
        """
        Initialize reactive rate limiter.

        Args:
            show_progress: Show progress bar during sleep. Defaults from config.
            state_file: Path to state file. Defaults from config.
        """
        settings = get_settings()
        rate_config = settings.rate_limiting

        self.short_term_sleep_minutes = rate_config.short_term_sleep_minutes
        self.daily_sleep_hours = rate_config.daily_sleep_hours
        self.max_retries_before_daily = rate_config.max_retries_before_daily_wait
        self.show_progress = (
            show_progress
            if show_progress is not None
            else rate_config.show_progress_bar
        )

        self._state_manager = RateLimitStateManager(state_file)
        self._lock = Lock()
        self._total_requests = 0

        logger.info(
            f"Reactive rate limiter initialized: "
            f"15-min sleep={self.short_term_sleep_minutes}min, "
            f"daily sleep={self.daily_sleep_hours}h"
        )

    def check_resume_status(self) -> None:
        """
        Check if we should wait before starting.

        Raises:
            RateLimitExceededError: If daily limit was hit and resume time not reached
        """
        should_wait, resume_time = self._state_manager.should_wait_for_resume()
        if should_wait and resume_time:
            wait_seconds = (resume_time - datetime.now()).total_seconds()
            if wait_seconds > 0:
                logger.warning(
                    f"Daily rate limit was previously hit. "
                    f"Resume time: {resume_time.isoformat()}"
                )
                raise RateLimitExceededError(
                    f"Daily rate limit reached. Resume after {resume_time}",
                    resume_after=resume_time,
                )
        # Clear resume time if we're past it
        self._state_manager.clear_resume_time()

    def record_success(self, request_url: Optional[str] = None) -> None:
        """
        Record a successful request.

        Args:
            request_url: URL of the successful request
        """
        with self._lock:
            self._total_requests += 1
            self._state_manager.record_request()
            logger.debug(f"Request succeeded (total: {self._total_requests})")

    def handle_429(
        self,
        request_url: str,
        last_activity_id: Optional[int] = None,
        last_resource: Optional[str] = None,
    ) -> bool:
        """
        Handle a 429 rate limit response.

        Args:
            request_url: URL of the rate-limited request
            last_activity_id: Last successfully processed activity ID
            last_resource: Name of the resource being processed

        Returns:
            True if request should be retried after sleeping
            False if daily limit exceeded and pipeline should stop

        Raises:
            RateLimitExceededError: If daily limit exceeded and should stop
        """
        with self._lock:
            self._state_manager.record_429(request_url)
            retry_count = self._state_manager.state.current_request_retries

            logger.warning(
                f"Received 429 rate limit response (retry #{retry_count}) "
                f"for: {request_url}"
            )

            if retry_count > self.max_retries_before_daily:
                # Likely hit daily limit - save state and schedule resume
                return self._handle_daily_limit(
                    last_activity_id=last_activity_id,
                    last_resource=last_resource,
                )
            else:
                # First 429 - wait 15 minutes
                self._sleep_for_short_term_limit()
                return True

    def _sleep_for_short_term_limit(self) -> None:
        """Sleep for 15 minutes due to short-term rate limit."""
        sleep_seconds = self.short_term_sleep_minutes * 60

        logger.warning(
            f"Short-term rate limit hit (100 req/15min). "
            f"Sleeping for {self.short_term_sleep_minutes} minutes..."
        )

        if self.show_progress:
            self._sleep_with_progress(
                sleep_seconds,
                f"Rate limited - waiting {self.short_term_sleep_minutes} min",
            )
        else:
            time.sleep(sleep_seconds)

        logger.info("Waking up from short-term rate limit sleep")

    def _handle_daily_limit(
        self,
        last_activity_id: Optional[int] = None,
        last_resource: Optional[str] = None,
    ) -> bool:
        """
        Handle daily rate limit exceeded.

        Args:
            last_activity_id: Last successfully processed activity ID
            last_resource: Name of the resource being processed

        Returns:
            False to indicate pipeline should stop

        Raises:
            RateLimitExceededError: Always raised to stop pipeline
        """
        resume_time = datetime.now() + timedelta(hours=self.daily_sleep_hours)

        # Save state for resumption
        self._state_manager.save_pipeline_state(
            last_activity_id=last_activity_id,
            last_resource=last_resource,
        )
        self._state_manager.set_resume_time(resume_time)

        logger.error(
            f"Daily rate limit hit (1000 req/day). "
            f"Saved state for resumption at {resume_time.isoformat()}"
        )

        raise RateLimitExceededError(
            f"Daily rate limit exceeded. Pipeline state saved. "
            f"Resume after {resume_time.isoformat()}",
            resume_after=resume_time,
        )

    def _sleep_with_progress(self, sleep_seconds: float, desc: str) -> None:
        """
        Sleep with a progress bar.

        Args:
            sleep_seconds: Number of seconds to sleep.
            desc: Description for the progress bar
        """
        print(f"\n{desc}")
        print(f"Total requests this session: {self._total_requests}")
        print(f"Total requests today: {self._state_manager.state.total_requests_today}")

        with tqdm(
            total=int(sleep_seconds),
            desc="Waiting",
            unit="s",
            ncols=80,
            colour="yellow",
            bar_format="{l_bar}{bar}| {remaining} remaining",
            file=sys.stdout,
        ) as pbar:
            for _ in range(int(sleep_seconds)):
                time.sleep(1)
                pbar.update(1)

        print()  # New line after progress bar

    def get_resume_info(self) -> Optional[dict]:
        """
        Get information for resuming after daily limit.

        Returns:
            Dict with resume info or None if no resume needed
        """
        return self._state_manager.get_resume_info()

    @property
    def total_requests(self) -> int:
        """Get total number of requests made this session."""
        return self._total_requests

    @property
    def total_requests_today(self) -> int:
        """Get total number of requests made today."""
        return self._state_manager.state.total_requests_today

    def reset_state(self) -> None:
        """Reset all rate limit state."""
        with self._lock:
            self._total_requests = 0
            self._state_manager.reset()
            logger.info("Rate limiter state reset")

    def __getstate__(self):
        """Get state for pickling."""
        state = self.__dict__.copy()
        del state["_lock"]
        return state

    def __setstate__(self, state):
        """Restore state from pickling."""
        self.__dict__.update(state)
        self._lock = Lock()
