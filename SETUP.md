# Strava Datastack - Setup & Run Guide

## Project Overview
This project extracts Strava activity data using `dlt` (Data Load Tool), loads it into DuckDB, and transforms it using dbt.

**Tech Stack:**
- **Extract & Load**: dlt (Data Load Tool) with REST API source
- **Warehouse**: DuckDB
- **Transform**: dbt-core with dbt-duckdb adapter
- **Package Manager**: uv

## Project Structure
```
strava-datastack/
├── extract/
│   └── strava.py              # Main dlt pipeline script
├── transform/                  # dbt project
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── models/
│   │   ├── staging/           # Raw data views
│   │   ├── intermediate/      # Intermediate transformations
│   │   └── core/              # Final fact tables
│   └── packages.yml           # dbt package dependencies
├── .dlt/
│   └── config.toml            # dlt configuration
├── pyproject.toml             # Python dependencies
└── uv.lock                    # Dependency lock file
```

## Prerequisites
1. **Python 3.11+** (specified in pyproject.toml)
2. **uv package manager** - Install from https://github.com/astral-sh/uv
3. **Strava API credentials** (see Authentication section below)

## Installation

### 1. Install Dependencies
```bash
uv sync
```

This installs:
- `dlt[duckdb]>=1.3.0` - Data extraction and loading
- `dbt-core>=1.9.1` - Transformation framework
- `dbt-duckdb>=1.9.1` - DuckDB adapter for dbt
- `psutil>=6.1.1` - System utilities
- `tqdm>=4.67.1` - Progress bars

### 2. Install dbt Packages
```bash
cd transform
uv run dbt deps
```

This installs dbt packages:
- `dbt-labs/dbt_utils` - Common dbt macros
- `dbt-labs/codegen` - Code generation utilities
- `calogica/dbt_expectations` - Data quality tests

## Authentication Setup

### Create Strava API Application
1. Go to https://www.strava.com/settings/api
2. Create a new application
3. Note your `client_id` and `client_secret`

### Generate Refresh Token with Proper Scopes

The default tokens from Strava API settings are insufficient because:
- Access tokens expire after 6 hours
- Initial refresh token only has `read` scope (not `activity:read`)

Generate a properly scoped refresh token:

1. **Build authorization URL** (replace `[YOUR_CLIENT_ID]`):
```
https://www.strava.com/oauth/authorize?client_id=[YOUR_CLIENT_ID]&response_type=code&redirect_uri=http://localhost/exchange_token&approval_prompt=force&scope=read_all,activity:read_all,profile:read_all
```

2. **Authorize in browser**:
   - Paste URL in browser
   - Approve the application
   - You'll get a "This site can't be reached" error - this is expected
   - Copy the `code` value from the URL (e.g., `http://localhost/exchange_token?code=XXXXX`)

3. **Exchange code for refresh token**:
```bash
curl -X POST https://www.strava.com/oauth/token \
  -F client_id=YOUR_CLIENT_ID \
  -F client_secret=YOUR_CLIENT_SECRET \
  -F code=AUTHORIZATION_CODE \
  -F grant_type=authorization_code
```

4. Save the `refresh_token` from the response

### Configure dlt Credentials

Create `.dlt/secrets.toml`:
```toml
[sources.strava.credentials]
access_token_url = "https://www.strava.com/oauth/token"
client_id = "YOUR_CLIENT_ID"
client_secret = "YOUR_CLIENT_SECRET"
refresh_token = "YOUR_REFRESH_TOKEN"
```

**Security Note**: The `.dlt/secrets.toml` file should never be committed to git (it should be in `.gitignore`)

## Running the Pipeline

### Extract & Load (dlt)

The main extraction script is `extract/strava.py` which:
- Uses OAuth2 with automatic token refresh
- Implements rate limiting (95 requests per 15 minutes per Strava API limits)
- Extracts three resources:
  - `activities` - Activity metadata
  - `activity_streams` - Time-series data (heart rate, speed, etc.)
  - `activity_zones` - Heart rate/power zones

#### Basic Run (Last 30 Days)
```bash
uv run extract/strava.py
```

**Default behavior** (from `strava.py:118-121`):
- Uses incremental loading with state management
- If no previous state exists, loads last 30 days
- Saves state for next incremental run

#### Historical Load with Start Date
```bash
uv run extract/strava.py --start-date='2024-01-01'
```

#### Backfill with Date Range
```bash
uv run extract/strava.py --start-date='2024-01-01' --end-date='2024-07-01'
```

**Important**: If you've already run the pipeline, you need `--end-date` for backfills because dlt stores a `last_value` in state.

#### Pipeline Configuration (from `strava.py:250-255`)
- **Pipeline name**: `strava_datastack`
- **Destination**: DuckDB
- **Dataset name**: `strava`
- **DuckDB location**: `.dlt/strava_datastack.duckdb` (dlt default)

#### Rate Limiting
The script implements a custom rate limiter (`strava.py:52-109`):
- Max 95 requests per 15 minutes
- Displays progress bar during rate limit waits
- Tracks total request count

#### Incremental Loading
Activities use incremental loading (`strava.py:163-170`):
- `cursor_path`: `start_date` field
- `start_param`: `after` (epoch timestamp for Strava API)
- `end_param`: `before` (epoch timestamp for Strava API)
- State persisted between runs for incremental updates

### Transform (dbt)

#### Set Environment Variable
dbt requires `DUCKDB_PATH` environment variable (from `transform/profiles.yml:9`):

```bash
export DUCKDB_PATH=".dlt/strava_datastack.duckdb"
```

Or set it inline:
```bash
DUCKDB_PATH=".dlt/strava_datastack.duckdb" uv run dbt run --project-dir transform
```

#### Run dbt Models
```bash
# Run all models
uv run dbt run --project-dir transform

# Run specific model
uv run dbt run --project-dir transform --select fct_activities

# Run staging models only
uv run dbt run --project-dir transform --select staging.*
```

#### dbt Project Structure (from `dbt_project.yml:32-39`)
- **Staging models** (`staging/`): Views on raw dlt tables
- **Intermediate models** (`intermediate/`): Tables for data preparation
- **Core models** (`core/`): Final fact tables

#### Test Data Quality
```bash
uv run dbt test --project-dir transform
```

## Data Models

### Staging Layer (Views)
- `stg_strava_activities` - Raw activities
- `stg_strava_activity_streams` - Raw time-series data
- `stg_strava_activity_zones` - Raw zone data
- `stg_strava_activity_zone_types` - Zone type reference
- `stg_strava_dlt_loads` - Load metadata

### Intermediate Layer (Tables)
- `int_activity_streams` - Processed streams
- `int_activity_stream_points` - Individual data points

### Core Layer (Tables)
- `fct_activities` - Activity facts
- `fct_activity_zones` - Zone facts
- `fct_activity_data_points` - Time-series facts

## Troubleshooting

### Check dlt Pipeline State
```bash
uv run dlt pipeline strava_datastack info -v
```

This shows:
- Current `last_value` for incremental loading
- Load history
- State information

### View Logs
dlt logs are written to `.dlt/strava.log` (configured in `strava.py:15-20`)

### Rate Limit Issues
Strava API limits: 100 requests per 15 minutes, 1000 requests per day

If you hit the daily limit:
- The pipeline will error
- Reduce date range with `--start-date` and `--end-date`
- Retry the next day

### Reset Pipeline State
```bash
uv run dlt pipeline strava_datastack drop
```

**Warning**: This removes all state and loaded data

## Development Commands

### Run Python Script
```bash
uv run extract/strava.py
```

### Enter Virtual Environment
```bash
source .venv/bin/activate
python extract/strava.py
```

### dbt Commands
```bash
# Compile models
uv run dbt compile --project-dir transform

# Generate documentation
uv run dbt docs generate --project-dir transform

# Serve documentation
uv run dbt docs serve --project-dir transform
```