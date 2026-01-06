#!/bin/bash
# Helper script to run the Strava extract pipeline

set -e

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and fill in your credentials"
    exit 1
fi

# Run the pipeline
echo "Running Strava extract pipeline..."
python -m strava_extract "$@"
