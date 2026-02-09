# Data Lineage (Marquez)

[Marquez](https://marquezproject.ai/) provides OpenLineage-based data lineage tracking for the Strava data pipeline.

## Services

| Service       | Port       | Image                               | Description                 |
|---------------|------------|-------------------------------------|-----------------------------|
| `marquez`     | 5000, 5001 | `marquezproject/marquez:0.51.1`     | Lineage API server          |
| `marquez-web` | 3200       | `marquezproject/marquez-web:0.51.1` | Web UI                      |
| `marquez-db`  | -          | `postgres:16`                       | PostgreSQL metadata storage |

## Architecture

```
┌─────────────────┐     OpenLineage Events      ┌──────────────────┐
│     Airflow     │ ──────────────────────────► │     Marquez      │
│  (OpenLineage   │                             │   (API: 5000)    │
│    Provider)    │                             └────────┬─────────┘
└─────────────────┘                                      │
                                                         │
┌─────────────────┐                             ┌────────▼─────────┐
│   dbt (Cosmos)  │ ──────────────────────────► │   Marquez Web    │
│                 │                             │   (UI: 3100)     │
└─────────────────┘                             └──────────────────┘
```

## Accessing the UI

- URL: http://localhost:3200
- No authentication required (development mode)

### Features

- **Dataset Lineage**: View upstream and downstream dependencies
- **Job History**: Track job runs and their outcomes
- **Schema Evolution**: Monitor dataset schema changes
- **Run Metadata**: Inspect run-level details and facets

## Configuration

Copy `.env.example` to `.env` to configure credentials:

```bash
cp .env.example .env
```

### Environment Variables

| Variable                    | Default   | Description       |
|-----------------------------|-----------|-------------------|
| `MARQUEZ_POSTGRES_USER`     | `marquez` | Database user     |
| `MARQUEZ_POSTGRES_PASSWORD` | `marquez` | Database password |
| `MARQUEZ_POSTGRES_DB`       | `marquez` | Database name     |
| `MARQUEZ_PORT`              | `5000`    | API port          |
| `MARQUEZ_ADMIN_PORT`        | `5001`    | Admin/health port |

### Airflow Integration

Airflow sends lineage events via the OpenLineage provider. Configuration in `docker-compose.yml`:

```yaml
OPENLINEAGE_NAMESPACE: strava-datastack
AIRFLOW__OPENLINEAGE__NAMESPACE: strava-datastack
AIRFLOW__OPENLINEAGE__TRANSPORT: '{"type":"http","url":"http://marquez:5000","endpoint":"api/v1/lineage"}'
```

## API Endpoints

### Lineage API (Port 5000)

| Endpoint                                      | Description          |
|-----------------------------------------------|----------------------|
| `GET /api/v1/namespaces`                      | List namespaces      |
| `GET /api/v1/namespaces/{namespace}/datasets` | List datasets        |
| `GET /api/v1/namespaces/{namespace}/jobs`     | List jobs            |
| `GET /api/v1/lineage?nodeId={id}`             | Get lineage graph    |
| `POST /api/v1/lineage`                        | Submit lineage event |

### Admin API (Port 5001)

| Endpoint           | Description  |
|--------------------|--------------|
| `GET /healthcheck` | Health check |

## OpenLineage Events

The pipeline emits standard OpenLineage events:

### Job Events

- `START`: Job execution begins
- `COMPLETE`: Job execution succeeds
- `FAIL`: Job execution fails

### Dataset Events

- Input datasets (data read)
- Output datasets (data written)
- Schema facets (column definitions)

## Viewing Lineage

1. Open http://localhost:3200
2. Browse datasets or jobs
3. Click a node to view its lineage graph

### Example Lineage

```
strava://api
    │
    ▼
strava_data_pipeline.extract_strava_data
    │
    ▼
duckdb://strava_datastack/raw
    │
    ▼
strava_data_pipeline.dbt_transform.*
    │
    ▼
duckdb://strava_datastack/analytics
duckdb://strava_reporting/reporting
```

## Data Retention

Marquez stores lineage data in PostgreSQL. The `marquez-db-volume` volume persists data across restarts. For production,
consider:

- Regular database backups
- Index maintenance
- Retention policies for old runs
