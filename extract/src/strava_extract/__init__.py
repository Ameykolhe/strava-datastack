"""Strava Extract - Production-ready data extraction pipeline for Strava API."""

__version__ = "0.1.0"

from .config.settings import get_credentials, get_settings
from .pipeline import StravaPipeline, run_pipeline
from .sources.strava_source import strava_source

__all__ = [
    "run_pipeline",
    "StravaPipeline",
    "strava_source",
    "get_settings",
    "get_credentials",
]
