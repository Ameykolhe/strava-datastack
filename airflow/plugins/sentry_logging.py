"""Attach a Sentry log event handler so Airflow logs become Sentry events."""

import logging
import os

import sentry_sdk
from sentry_sdk.integrations.logging import EventHandler


def _attach_sentry_log_handler() -> None:
    level_name = os.getenv("SENTRY_LOG_LEVEL", "INFO").upper()
    level = getattr(logging, level_name, logging.INFO)

    root_logger = logging.getLogger()
    for handler in root_logger.handlers:
        if isinstance(handler, EventHandler):
            return

    handler = EventHandler(level=level)
    handler.setLevel(level)
    root_logger.addHandler(handler)


_attach_sentry_log_handler()
