import argparse
import logging
import time
from datetime import datetime, timedelta
from typing import Any

import dlt
from dlt.sources.helpers.rest_client.auth import OAuth2ClientCredentials
from dlt.sources.helpers.rest_client.paginators import PageNumberPaginator
from dlt.sources.helpers.requests import Request
from dlt.common.pendulum import pendulum
from dlt.sources.rest_api import RESTAPIConfig, rest_api_resources
from tqdm import tqdm

logging.basicConfig(
    filename='.dlt/strava.log',
    filemode='w',
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)

logging.getLogger("urllib3").setLevel(logging.DEBUG)

class OAuth2ClientCredentialsHTTPRefresh(OAuth2ClientCredentials):
    def build_access_token_request(self) -> dict[str, Any]:
        return {
            "headers": {
                "Content-Type": "application/x-www-form-urlencoded",
            },
            "data": self.access_token_request_data,
        }

def auth_strava():
    return OAuth2ClientCredentialsHTTPRefresh(
        access_token_url=dlt.secrets["sources.strava.credentials.access_token_url"],
        access_token_request_data={
            "grant_type": "refresh_token",
            "refresh_token": dlt.secrets["sources.strava.credentials.refresh_token"],
            "client_id": dlt.secrets["sources.strava.credentials.client_id"],
            "client_secret": dlt.secrets["sources.strava.credentials.client_secret"],
        },
        default_token_expiration=21600
    )

def parse_arguments():
    parser = argparse.ArgumentParser(description="Run the DLT pipeline.")
    parser.add_argument("--start-date", type=str, default=None, help="Specify the start date >= for loading data (e.g. '2024-01-01')")
    parser.add_argument("--end-date", type=str, default=None, help="Specify the end date < for loading data (e.g. '2024-07-01')")
    return parser.parse_args()

class SharedRateLimiter:
    def __init__(self, max_requests, period):
        self.max_requests = max_requests
        self.period = period
        self.session_requests = 0
        self.total_requests = 0
        self.start_time = datetime.now()

    def request(self):
        if self.session_requests >= self.max_requests:
            self.sleep()
            self.session_requests = 0
        self.session_requests += 1
        self.total_requests += 1

    def sleep(self):
        end_time = self.start_time + self.period
        sleep_time = (end_time - datetime.now()).total_seconds()
        if sleep_time > 0:
            self.loading_bar(sleep_time)
        self.start_time = datetime.now()
    
    def loading_bar(self, sleep_time):
        """
        Loading bar to track and provide a visual of sleep time.

        When the "loading" completes, the next batch of requests will be made.
        """
        print("Rate limit reached. Waiting...")
        self.print_request_count()
        with tqdm(total=int(sleep_time), desc="Sleeping", unit="s", ncols=80, colour='blue', bar_format="{l_bar}{bar}| {remaining} seconds remaining") as pbar:
            for _ in range(int(sleep_time)):
                time.sleep(1)
                pbar.update(1)
    
    def print_request_count(self):
        print(f"Total request count: {self.total_requests}")

class RateLimitedPageNumberPaginator(PageNumberPaginator):
    def __init__(self, rate_limiter, resource_name, **kwargs):
        super().__init__(**kwargs)
        self.rate_limiter = rate_limiter
        self.resource_name = resource_name
        self.resource_requests = 0

    def update_request(self, request: Request) -> None:
        super().update_request(request)
        self.rate_limiter.request()
        self.resource_requests += 1
        self.print_request_count()

    def print_request_count(self):
        print(f"Resource {self.resource_name} request count: {self.resource_requests}")

shared_rate_limiter = SharedRateLimiter(
    max_requests=95,
    period=timedelta(minutes=15)
)

@dlt.source(name="strava")
def strava_source(start_date: str | None = None, end_date: str | None = None):
    load_from_date = (
        pendulum.parse(start_date).to_iso8601_string()
        if start_date
        else dlt.current.source_state().setdefault(
                "last_value",
                pendulum.today().subtract(days=30).to_iso8601_string()
        )
    )

    load_until_date = (
        pendulum.parse(end_date).to_iso8601_string()
        if end_date
        else None
    )

    config: RESTAPIConfig = {
        "client": {
            "base_url": "https://www.strava.com/api/v3/",
            "auth": auth_strava()
        },
        "resource_defaults": {
            "primary_key": "id",
            "write_disposition": "merge",
            "endpoint": {
                "params": {
                    "per_page": 200,
                },
            },
        },
        "resources": [
            {
                "name": "activities",
                "primary_key": "id",
                "endpoint": {
                    "path": "activities",
                    "paginator": RateLimitedPageNumberPaginator(rate_limiter=shared_rate_limiter, base_page=1, total_path=None, resource_name="activities"),
                    "incremental": {
                        "start_param": "after",
                        "end_param": "before",
                        "cursor_path": "start_date",
                        "initial_value": load_from_date,
                        "end_value": load_until_date,
                        "convert": lambda timestamp_str: None if timestamp_str is None else int(pendulum.parse(timestamp_str).timestamp()),
                    },
                },
            },
            {
                "name": "activity_streams",
                "primary_key": ["_activities_id", "type"],
                "max_table_nesting": 0,
                "endpoint": {
                    "path": "activities/{activity_id}/streams",
                    "response_actions": [
                        {"status_code": 404, "content": "Not Found", "action": "ignore"},
                    ],
                    "paginator": RateLimitedPageNumberPaginator(
                            rate_limiter=shared_rate_limiter,
                            base_page=1,
                            total_path=None,
                            maximum_page=1,
                            resource_name="activity_streams"
                        ),
                    "params": {
                        "keys": "time,distance,altitude,velocity_smooth,heartrate,cadence,watts,temp,moving,grade_smooth,latlng",
                        "activity_id": {
                            "type": "resolve",
                            "resource": "activities",
                            "field": "id",
                        }
                    },
                },
                "include_from_parent": ["id"],
            },
            {
                "name": "activity_zones",
                "primary_key": ["_activities_id", "type"], # _activites_id comes from the parent activity; see include_from_parent
                "endpoint": {
                    "path": "activities/{activity_id}/zones",
                    "response_actions": [
                        {"status_code": 404, "content": "Not Found", "action": "ignore"},
                    ],
                    "paginator": RateLimitedPageNumberPaginator(
                            rate_limiter=shared_rate_limiter,
                            base_page=1,
                            total_path=None,
                            maximum_page=1,
                            resource_name="activity_zones"
                        ),
                    "params": {
                        "activity_id": {
                            "type": "resolve",
                            "resource": "activities",
                            "field": "id",
                        }
                    },
                },
                "include_from_parent": ["id"],
            },
        ],
    }

    yield from rest_api_resources(config)

def load_strava() -> None:
    args = parse_arguments()
    start_date = args.start_date
    end_date = args.end_date

    pipeline = dlt.pipeline(
        pipeline_name="strava_datastack",
        destination='duckdb',
        dataset_name="strava_raw",
        progress="log",
    )

    load_info = pipeline.run((strava_source(start_date=start_date, end_date=end_date)))
    print(load_info)


if __name__ == "__main__":
    load_strava()
