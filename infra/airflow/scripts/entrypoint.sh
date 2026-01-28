#!/bin/bash
set -e

# Install the extract package in editable mode if not already installed
if [ -d "/opt/airflow/extract" ]; then
    echo "Installing strava-extract package..."
    pip install --no-cache-dir -e /opt/airflow/extract
else
    echo "Warning: /opt/airflow/extract directory not found"
fi

# Health check: ensure strava_extract is importable before starting Airflow
python - <<'PY'
import importlib
import sys

try:
    importlib.import_module("strava_extract")
except Exception as exc:
    print(f"ERROR: strava_extract not importable: {exc}", file=sys.stderr)
    sys.exit(1)
PY

# Execute the original Airflow entrypoint with all arguments
exec /entrypoint "$@"
