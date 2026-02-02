# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# DuckDB database paths
export DUCKDB_PATH="$SCRIPT_DIR/infra/airflow/data/strava_datastack.duckdb"
export DUCKDB_REPORTING_PATH="$SCRIPT_DIR/infra/airflow/data/strava_reporting.duckdb"
