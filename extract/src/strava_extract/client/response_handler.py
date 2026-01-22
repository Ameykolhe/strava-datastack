"""Custom response handling with reactive rate limiting."""

from typing import Callable, Optional

from requests import Response

from ..utils.logging import get_logger
from .rate_limiter import RateLimiter, RateLimitExceededError

logger = get_logger(__name__)


class RateLimitResponseHandler:
    """
    Handles HTTP responses with reactive rate limiting.

    Intercepts 429 responses and applies rate limit handling:
    - First 429: Sleep 15 minutes and retry
    - Second 429: Save state and raise exception to stop pipeline
    """

    def __init__(
        self,
        rate_limiter: RateLimiter,
        resource_name: str = "unknown",
    ):
        """
        Initialize response handler.

        Args:
            rate_limiter: Shared rate limiter instance
            resource_name: Name of the resource being fetched
        """
        self.rate_limiter = rate_limiter
        self.resource_name = resource_name
        self._last_activity_id: Optional[int] = None

    def set_last_activity_id(self, activity_id: int) -> None:
        """Track the last successfully processed activity ID."""
        self._last_activity_id = activity_id

    def handle_response(self, response: Response) -> Response:
        """
        Handle HTTP response, processing 429 rate limits.

        Args:
            response: The HTTP response

        Returns:
            The response if successful

        Raises:
            RateLimitExceededError: If daily limit exceeded
        """
        if response.status_code == 429:
            request_url = response.request.url or "unknown"
            logger.warning(
                f"Rate limit 429 received for {self.resource_name}: {request_url}"
            )

            # This will sleep or raise RateLimitExceededError
            self.rate_limiter.handle_429(
                request_url=str(request_url),
                last_activity_id=self._last_activity_id,
                last_resource=self.resource_name,
            )
            # If we get here, we should retry the request
            # The caller should handle retry logic

        elif response.ok:
            # Record successful request
            self.rate_limiter.record_success(response.request.url)

        return response


def create_rate_limit_response_action(
    rate_limiter: RateLimiter,
    resource_name: str = "unknown",
) -> Callable[[Response], Optional[str]]:
    """
    Create a response action function for dlt REST client.

    This function can be used in the response_actions config to handle 429 errors.

    Args:
        rate_limiter: Shared rate limiter instance
        resource_name: Name of the resource

    Returns:
        A callable that processes responses and returns action string
    """
    handler = RateLimitResponseHandler(rate_limiter, resource_name)
    _last_activity_id: Optional[int] = None

    def response_action(response: Response) -> Optional[str]:
        """
        Process response and determine action.

        Returns:
            "retry" if request should be retried
            None to continue normally
        """
        nonlocal _last_activity_id

        if response.status_code == 429:
            request_url = str(response.request.url or "unknown")
            logger.warning(
                f"Rate limit 429 for {resource_name}: {request_url}"
            )

            # This will either sleep and return True (retry),
            # or raise RateLimitExceededError (stop)
            try:
                should_retry = rate_limiter.handle_429(
                    request_url=request_url,
                    last_activity_id=_last_activity_id,
                    last_resource=resource_name,
                )
                if should_retry:
                    return "retry"
            except RateLimitExceededError:
                raise

        elif response.ok:
            rate_limiter.record_success(str(response.request.url))

        return None

    return response_action


def create_response_hooks(
    rate_limiter: RateLimiter,
    resource_name: str,
) -> dict:
    """
    Create hooks dict for dlt REST client configuration.

    Args:
        rate_limiter: Shared rate limiter instance
        resource_name: Name of the resource

    Returns:
        Dict with response hooks for requests library
    """
    handler = RateLimitResponseHandler(rate_limiter, resource_name)

    def response_hook(response: Response, *args, **kwargs) -> Response:
        """Hook called after each response."""
        return handler.handle_response(response)

    return {"response": [response_hook]}
