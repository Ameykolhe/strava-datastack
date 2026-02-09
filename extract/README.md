# Strava Extract Pipeline

Production-ready Strava API data extraction using [dlt](https://dlthub.com/) (data load tool).

## Features

- **OAuth2 Authentication**: Automatic token refresh with secure credential management
- **Reactive Rate Limiting**: Intelligent 429 handling with automatic backoff (100 req/15min, 1000/day)
- **Schema Contracts**: Enforced data types and constraints via dlt schemas
- **OpenTelemetry Integration**: Distributed tracing and logging to OTEL collector
- **Incremental Loading**: Efficient date-range based extraction with cursor tracking
- **Configurable Resources**: YAML-driven endpoint configuration

## Installation

```bash
make install      # Install dependencies with uv
make install-dev  # Install with development dependencies
```

## Configuration

### Configuration Files

| File                    | Purpose                                     |
|-------------------------|---------------------------------------------|
| `config/config.yaml`    | Pipeline settings, rate limiting, telemetry |
| `config/resources.yaml` | API endpoint and resource definitions       |
| `.env`                  | Strava API credentials                      |

### Environment Variables

| Variable                     | Description              | Required                                  |
|------------------------------|--------------------------|-------------------------------------------|
| `CREDENTIALS__CLIENT_ID`     | Strava API client ID     | Yes                                       |
| `CREDENTIALS__CLIENT_SECRET` | Strava API client secret | Yes                                       |
| `CREDENTIALS__REFRESH_TOKEN` | OAuth refresh token      | Yes                                       |
| `DUCKDB_PATH`                | Output database path     | No (default: `./strava_datastack.duckdb`) |

### Obtaining Strava Credentials

1. Create an application at https://www.strava.com/settings/api
2. Note your Client ID and Client Secret
3. Generate a refresh token using the OAuth flow or a tool like [strava-oauth](https://github.com/mgryszko/strava-oauth)

## Makefile Targets

| Target                                               | Description                          |
|------------------------------------------------------|--------------------------------------|
| `make help`                                          | Show all available targets           |
| `make install`                                       | Install dependencies                 |
| `make install-dev`                                   | Install development dependencies     |
| `make run`                                           | Run pipeline (default: last 30 days) |
| `make run START_DATE=YYYY-MM-DD END_DATE=YYYY-MM-DD` | Run with date range                  |
| `make run DEBUG=1`                                   | Run with debug logging               |

## Usage

### Basic Extraction

```bash
# Extract last 30 days (default)
make run

# Extract specific date range
make run START_DATE=2024-01-01 END_DATE=2024-12-31

# Debug mode with verbose logging
make run DEBUG=1
```

### Programmatic Usage

```python
from strava_extract import run_pipeline

# Default extraction (last 30 days)
load_info = run_pipeline()

# Custom date range
load_info = run_pipeline(
    start_date="2024-01-01",
    end_date="2024-12-31"
)
```

## Pipeline Components

### Authentication (`auth.py`)

Handles OAuth2 token refresh using client credentials. Tokens are automatically refreshed when expired.

### Rate Limiter (`rate_limiter.py`)

Reactive rate limiting that only triggers on HTTP 429 responses:

- First 429: Sleep for 15 minutes (short-term limit)
- Second 429: Sleep for 24 hours (daily limit)

### Paginator

Handles Strava's page-based pagination with configurable page size (default: 200, max: 200).

### Source (`strava_source.py`)

dlt source that yields resources based on `resources.yaml` configuration.

## Output Tables

| Table                      | Description                             | Primary Key              |
|----------------------------|-----------------------------------------|--------------------------|
| `activities`               | Activity summaries (runs, rides, etc.)  | `id`                     |
| `activity_streams`         | Time-series data (HR, power, GPS)       | `_activities_id`, `type` |
| `activity_zones`           | Heart rate and power zone distributions | `_activities_id`, `type` |
| `activity_segment_efforts` | Segment performance attempts            | `id`                     |

## Rate Limiting Strategy

The pipeline uses a **reactive** approach to rate limiting:

```yaml
rate_limiting:
  short_term_limit: 100      # 100 requests per 15 minutes
  daily_limit: 1000          # 1000 requests per day
  short_term_sleep_minutes: 15
  daily_sleep_hours: 24
```

Rather than proactively tracking request counts, the pipeline:

1. Makes requests until hitting a 429 response
2. Sleeps for the appropriate duration
3. Retries the failed request
4. Persists state to resume after restarts

## Observability

The pipeline exports telemetry via OpenTelemetry:

```yaml
telemetry:
  enabled: true
  endpoint: "http://otel-collector:4318"
  service_name: "strava-extract"
  enable_traces: true
  enable_logs: true
```

Traces and logs are sent to the OTEL collector and can be viewed in:

- **Jaeger**: http://localhost:16686 (traces)
- **Grafana/Loki**: http://localhost:3000 (logs)

## Schema Contracts

dlt enforces schemas defined in `resources.yaml`:

```yaml
resources:
  - name: "activities"
    primary_key: "id"
    write_disposition: "merge"
    columns:
      location_city:
        data_type: "text"
        nullable: true
```

The `merge` write disposition enables efficient incremental updates using the primary key.
