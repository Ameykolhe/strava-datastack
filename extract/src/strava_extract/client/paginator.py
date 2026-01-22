"""Custom pagination for Strava API resources."""

from typing import Optional

from dlt.sources.helpers.requests import Request
from dlt.sources.helpers.rest_client.paginators import PageNumberPaginator

from ..utils.logging import get_logger

logger = get_logger(__name__)


class StravaPagePaginator(PageNumberPaginator):
    """
    Page number paginator for Strava API resources.

    Extends dlt's PageNumberPaginator with request tracking for logging.
    Rate limiting is handled reactively via response handlers, not here.
    """

    def __init__(
        self,
        resource_name: str,
        base_page: int = 1,
        total_path: Optional[str] = None,
        maximum_page: Optional[int] = None,
        **kwargs,
    ):
        """
        Initialize paginator.

        Args:
            resource_name: Name of the resource (for logging).
            base_page: Starting page number.
            total_path: JSON path to total pages (if available).
            maximum_page: Maximum page to fetch (if known).
            **kwargs: Additional arguments for PageNumberPaginator.
        """
        super().__init__(
            base_page=base_page,
            total_path=total_path,
            maximum_page=maximum_page,
            **kwargs,
        )
        self.resource_name = resource_name
        self._resource_requests = 0

        logger.debug(f"Paginator initialized for resource: {resource_name}")

    def update_request(self, request: Request) -> None:
        """
        Update request with pagination parameters.

        Args:
            request: The request to update.
        """
        # Call parent to handle pagination logic
        super().update_request(request)

        # Track resource-specific requests
        self._resource_requests += 1

        logger.debug(
            f"Request prepared for {self.resource_name}: "
            f"total_requests={self._resource_requests}"
        )

        # Log every 10 requests for this resource
        if self._resource_requests % 10 == 0:
            logger.info(
                f"Resource '{self.resource_name}' progress: "
                f"{self._resource_requests} requests made"
            )

    @property
    def resource_requests(self) -> int:
        """Get number of requests made for this resource."""
        return self._resource_requests
