"""Thread-safe rate limiter for Strava API requests."""

import time
from datetime import datetime, timedelta
from threading import Lock
from typing import Optional

from tqdm import tqdm  # type: ignore[import-untyped]

from ..config.settings import get_settings
from ..utils.logging import get_logger

logger = get_logger(__name__)


class RateLimiter:
    """
    Thread-safe rate limiter for Strava API requests.

    Implements a sliding window rate limiter that enforces Strava's
    95 requests per 15 minutes limit across all resources.
    """

    def __init__(
        self,
        max_requests: Optional[int] = None,
        period: Optional[timedelta] = None,
        show_progress: Optional[bool] = None,
    ):
        """
        Initialize rate limiter.

        Args:
            max_requests: Maximum requests per period. Defaults from config.
            period: Time period for rate limit. Defaults from config.
            show_progress: Show progress bar during sleep. Defaults from config.
        """
        settings = get_settings()

        self.max_requests = max_requests or settings.rate_limiting.max_requests
        self.period = period or timedelta(minutes=settings.rate_limiting.period_minutes)
        self.show_progress = (
            show_progress
            if show_progress is not None
            else settings.rate_limiting.show_progress_bar
        )

        self._session_requests = 0
        self._total_requests = 0
        self._start_time = datetime.now()
        self._lock = Lock()

        logger.info(
            f"Rate limiter initialized: {self.max_requests} requests per {self.period}"
        )

    def acquire(self) -> None:
        """
        Acquire permission to make a request.

        Blocks if rate limit is exceeded until the current period expires.
        Thread-safe.
        """
        with self._lock:
            if self._session_requests >= self.max_requests:
                self._wait_for_reset()
                self._session_requests = 0
                self._start_time = datetime.now()

            self._session_requests += 1
            self._total_requests += 1

            logger.debug(
                f"Request acquired: {self._session_requests}/{self.max_requests} "
                f"(total: {self._total_requests})"
            )

    def _wait_for_reset(self) -> None:
        """Wait until the current rate limit period expires."""
        end_time = self._start_time + self.period
        sleep_seconds = (end_time - datetime.now()).total_seconds()

        if sleep_seconds > 0:
            logger.warning(
                f"Rate limit reached ({self.max_requests} requests). "
                f"Sleeping for {sleep_seconds:.1f} seconds"
            )

            if self.show_progress:
                self._sleep_with_progress(sleep_seconds)
            else:
                time.sleep(sleep_seconds)

    def _sleep_with_progress(self, sleep_seconds: float) -> None:
        """
        Sleep with a progress bar.

        Args:
            sleep_seconds: Number of seconds to sleep.
        """
        print(
            f"\nRate limit reached. Waiting... "
            f"(Total requests: {self._total_requests})"
        )

        with tqdm(
            total=int(sleep_seconds),
            desc="Sleeping",
            unit="s",
            ncols=80,
            colour="blue",
            bar_format="{l_bar}{bar}| {remaining} seconds remaining",
        ) as pbar:
            for _ in range(int(sleep_seconds)):
                time.sleep(1)
                pbar.update(1)

    @property
    def total_requests(self) -> int:
        """Get total number of requests made."""
        return self._total_requests

    @property
    def session_requests(self) -> int:
        """Get number of requests in current period."""
        return self._session_requests

    def reset_stats(self) -> None:
        """Reset request counters (useful for testing)."""
        with self._lock:
            self._session_requests = 0
            self._total_requests = 0
            self._start_time = datetime.now()
            logger.info("Rate limiter stats reset")

    def __getstate__(self):
        """
        Get state for pickling.

        Excludes the Lock object which cannot be pickled.
        """
        state = self.__dict__.copy()
        # Remove the unpicklable Lock
        del state["_lock"]
        return state

    def __setstate__(self, state):
        """
        Restore state from pickling.

        Recreates the Lock object.
        """
        self.__dict__.update(state)
        # Recreate the Lock
        self._lock = Lock()
