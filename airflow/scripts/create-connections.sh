#!/bin/bash
set -e

echo "========================================="
echo "Setting up Strava credentials in Airflow"
echo "========================================="
echo ""

# Check if .env file exists in extract directory
ENV_FILE="../extract/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo ""
    echo "Please create the .env file with your Strava credentials:"
    echo "  CREDENTIALS__CLIENT_ID=your_client_id"
    echo "  CREDENTIALS__CLIENT_SECRET=your_client_secret"
    echo "  CREDENTIALS__REFRESH_TOKEN=your_refresh_token"
    echo ""
    exit 1
fi

# Source the .env file
echo "Reading credentials from $ENV_FILE..."
source "$ENV_FILE"

# Check if credentials are set
if [ -z "$CREDENTIALS__CLIENT_ID" ] || [ -z "$CREDENTIALS__CLIENT_SECRET" ] || [ -z "$CREDENTIALS__REFRESH_TOKEN" ]; then
    echo "Error: One or more credentials are missing in $ENV_FILE"
    echo ""
    echo "Required variables:"
    echo "  CREDENTIALS__CLIENT_ID"
    echo "  CREDENTIALS__CLIENT_SECRET"
    echo "  CREDENTIALS__REFRESH_TOKEN"
    echo ""
    exit 1
fi

# Check if Airflow is running
if ! docker compose ps | grep -q "airflow-worker"; then
    echo "Error: Airflow is not running."
    echo "Please run 'make up' or 'make init' first."
    exit 1
fi

echo "Creating Airflow Variables..."

# Create Airflow variables using worker container
docker compose exec -T airflow-worker airflow variables set \
  STRAVA_CLIENT_ID "$CREDENTIALS__CLIENT_ID" 2>/dev/null

docker compose exec -T airflow-worker airflow variables set \
  STRAVA_CLIENT_SECRET "$CREDENTIALS__CLIENT_SECRET" 2>/dev/null

docker compose exec -T airflow-worker airflow variables set \
  STRAVA_REFRESH_TOKEN "$CREDENTIALS__REFRESH_TOKEN" 2>/dev/null

echo ""
echo "========================================="
echo "Credentials configured successfully!"
echo "========================================="
echo ""
echo "You can now trigger the Strava pipeline:"
echo "  make trigger"
echo ""
echo "Or via Airflow UI: http://localhost:8080"
