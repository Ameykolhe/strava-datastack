"""Strava OAuth2 authentication implementation."""

from typing import Any, Dict
import os

from dlt.sources.helpers.rest_client.auth import OAuth2ClientCredentials

from ..utils.logging import get_logger
from ..utils.exceptions import AuthenticationError

logger = get_logger(__name__)


class StravaOAuth2(OAuth2ClientCredentials):
    """
    Strava-specific OAuth2 implementation with refresh token support.

    Extends dlt's OAuth2ClientCredentials to handle Strava's specific
    requirements for token refresh using application/x-www-form-urlencoded.
    """

    def build_access_token_request(self) -> Dict[str, Any]:
        """
        Build the access token request with Strava's required format.

        Strava requires application/x-www-form-urlencoded content type
        for OAuth token refresh requests.

        Returns:
            Request dict with headers and data for token refresh.
        """
        return {
            "headers": {
                "Content-Type": "application/x-www-form-urlencoded",
            },
            "data": self.access_token_request_data,
        }


def get_auth() -> StravaOAuth2:
    """
    Factory function to get authenticated Strava OAuth2 instance.

    Loads credentials from environment variables using dlt's naming convention:
    - CREDENTIALS__CLIENT_ID
    - CREDENTIALS__CLIENT_SECRET
    - CREDENTIALS__REFRESH_TOKEN
    - CREDENTIALS__ACCESS_TOKEN_URL (optional, defaults to Strava's token URL)

    Returns:
        Configured StravaOAuth2 instance.

    Raises:
        AuthenticationError: If credentials are missing or invalid.
    """
    try:
        # Load credentials from environment variables (dlt naming convention)
        client_id = os.getenv("CREDENTIALS__CLIENT_ID")
        client_secret = os.getenv("CREDENTIALS__CLIENT_SECRET")
        refresh_token = os.getenv("CREDENTIALS__REFRESH_TOKEN")
        access_token_url = os.getenv("CREDENTIALS__ACCESS_TOKEN_URL", "https://www.strava.com/oauth/token")

        # Validate required credentials
        if not all([client_id, client_secret, refresh_token]):
            raise AuthenticationError(
                "Missing required credentials. Please ensure CREDENTIALS__CLIENT_ID, "
                "CREDENTIALS__CLIENT_SECRET, and CREDENTIALS__REFRESH_TOKEN are set in your .env file."
            )

        # Create auth instance
        auth = StravaOAuth2(
            access_token_url=access_token_url,
            client_id=client_id,
            client_secret=client_secret,
            access_token_request_data={
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
                "client_id": client_id,
                "client_secret": client_secret,
            },
            default_token_expiration=21600  # 6 hours
        )

        logger.info("Strava OAuth2 authentication initialized")
        return auth

    except AuthenticationError:
        raise
    except Exception as e:
        logger.error(f"Failed to initialize OAuth2: {e}")
        raise AuthenticationError(
            f"Authentication initialization failed: {e}"
        ) from e
