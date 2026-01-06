"""Strava Extract - Production-ready data extraction pipeline for Strava API."""

__version__ = "0.1.0"

from .pipeline import run_pipeline, StravaPipeline
from .sources.strava_source import strava_source
from .config.settings import get_settings, get_credentials

__all__ = [
    "run_pipeline",
    "StravaPipeline",
    "strava_source",
    "get_settings",
    "get_credentials",
]
