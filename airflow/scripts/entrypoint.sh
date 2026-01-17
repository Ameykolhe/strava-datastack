#!/bin/bash
set -e

# Install the extract package in editable mode if not already installed
if [ -d "/opt/airflow/extract" ]; then
    echo "Installing strava-extract package..."
    pip install --no-cache-dir -e /opt/airflow/extract
else
    echo "Warning: /opt/airflow/extract directory not found"
fi

# Execute the original Airflow entrypoint with all arguments
exec /entrypoint "$@"
