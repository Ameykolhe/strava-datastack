# Strava DataStack

A personal Strava analytics platform that extracts activity data from the Strava API, transforms it using dbt, and
visualizes insights through Evidence.dev dashboards.

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Strava API  │───►│   Extract   │───►│  Transform  │───►│  Visualize  │
│             │    │    (dlt)    │    │    (dbt)    │    │ (Evidence)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                          │                  │                  │
                          ▼                  ▼                  ▼
                   ┌─────────────────────────────────────────────────────┐
                   │                        DuckDB                       │
                   │  strava_datastack.duckdb │ strava_reporting.duckdb  │
                   └─────────────────────────────────────────────────────┘
```

## Tech Stack

| Component      | Technology                                           | Purpose                                                           |
|----------------|------------------------------------------------------|-------------------------------------------------------------------|
| Extract        | [dlt](https://dlthub.com/)                           | Python data loading with OAuth2, rate limiting, schema contracts  |
| Transform      | [dbt](https://www.getdbt.com/) 1.9+                  | Data modeling with staging, intermediate, marts, reporting layers |
| Storage        | [DuckDB](https://duckdb.org/)                        | Embedded OLAP database for analytics                              |
| Visualize      | [Evidence.dev](https://evidence.dev/)                | Code-driven BI dashboards with SvelteKit                          |
| Orchestrate    | [Airflow](https://airflow.apache.org/) 3.x           | DAG-based workflow orchestration with Cosmos                      |
| Observability  | OpenTelemetry + Jaeger + Prometheus + Grafana + Loki | Distributed tracing, metrics, and logs                            |
| Lineage        | [Marquez](https://marquezproject.ai/)                | OpenLineage-based data lineage tracking                           |
| Infrastructure | Docker Compose                                       | Multi-service orchestration                                       |

## Repository Structure

```
strava-datastack/
├── extract/             # dlt pipeline for Strava API extraction
├── transform/           # dbt models for data transformation
├── visualize/           # Evidence.dev dashboards
├── airflow/             # DAGs, operators, and plugins
└── infra/               # Docker Compose infrastructure
    ├── airflow/         # Airflow services (API server, scheduler, workers)
    ├── observability/   # Monitoring stack (OTEL, Jaeger, Prometheus, Loki, Grafana)
    ├── lineage/         # Marquez data lineage
    └── strava-infra/    # Shared network configuration
```

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.11+
- Node.js 18+
- Strava API credentials ([create an app](https://www.strava.com/settings/api))

### 1. Clone and Configure

```bash
git clone https://github.com/your-username/strava-datastack.git
cd strava-datastack

# Copy environment template and add your credentials
cp .env.example .env
```

Required environment variables in `.env`:

```bash
CREDENTIALS__CLIENT_ID=your_strava_client_id
CREDENTIALS__CLIENT_SECRET=your_strava_client_secret
CREDENTIALS__REFRESH_TOKEN=your_strava_refresh_token
```

### 2. Start Infrastructure

```bash
cd infra
docker compose --profile airflow up -d
```

### 3. Configure Airflow Variables

Access Airflow UI at http://localhost:8080 (default: airflow/airflow) and set:

- `STRAVA_CLIENT_ID`
- `STRAVA_CLIENT_SECRET`
- `STRAVA_REFRESH_TOKEN`

### 4. Trigger the Pipeline

```bash
cd airflow
make trigger  # Default: last 30 days

# Or with custom date range
make trigger START_DATE=2024-01-01 END_DATE=2024-12-31
```

### 5. View Dashboards

Start the Evidence development server:

```bash
cd visualize
make install
make dev
```

Open http://localhost:3000 to view your Strava analytics.

## Data Flow

1. **Extract**: The dlt pipeline authenticates with Strava OAuth2, handles rate limiting (100 req/15min, 1000/day), and
   loads activities, streams, zones, and segment efforts into DuckDB.

2. **Transform**: dbt models process raw data through layers:
    - **Staging**: Clean and rename raw tables
    - **Intermediate**: Reshape and aggregate data
    - **Marts**: Business-logic facts and dimensions
    - **Reporting**: Denormalized tables optimized for Evidence queries

3. **Visualize**: Evidence.dev queries the reporting DuckDB and renders interactive dashboards with KPIs, streaks,
   trends, and activity details.

## Environment Variables

| Variable                     | Description                               | Used By              |
|------------------------------|-------------------------------------------|----------------------|
| `CREDENTIALS__CLIENT_ID`     | Strava API client ID                      | Extract              |
| `CREDENTIALS__CLIENT_SECRET` | Strava API client secret                  | Extract              |
| `CREDENTIALS__REFRESH_TOKEN` | Strava OAuth refresh token                | Extract              |
| `DUCKDB_PATH`                | Path to main DuckDB database              | Transform, Airflow   |
| `DUCKDB_REPORTING_PATH`      | Path to reporting DuckDB                  | Transform, Visualize |
| `STRAVA_ENVIRONMENT`         | Environment name (production/development) | All                  |

## Service URLs

| Service    | URL                    | Description                       |
|------------|------------------------|-----------------------------------|
| Airflow    | http://localhost:8080  | Workflow orchestration UI         |
| Grafana    | http://localhost:3000  | Metrics and log dashboards        |
| Jaeger     | http://localhost:16686 | Distributed tracing UI            |
| Prometheus | http://localhost:9090  | Metrics storage and queries       |
| Marquez    | http://localhost:3200  | Data lineage UI                   |
| Evidence   | http://localhost:4000  | Analytics dashboards (dev server) |
| Flower     | http://localhost:5555  | Celery worker monitoring          |

## TODO

- [ ] AWS S3 for reporting DB and syncing Netlify deploys from S3
- [ ] MCP server for accessing fact and dimension models
- [ ] Backend API for chat application
- [ ] Separate frontend / integrate chat application with Evidence (local/Docker only)

## Subproject Documentation

- [Extract Pipeline](./extract/README.md) - Strava API extraction with dlt
- [Transform Models](./transform/README.md) - dbt data transformations
- [Visualize Dashboards](./visualize/README.md) - Evidence.dev analytics
- [Airflow DAGs](./airflow/README.md) - Orchestration and operators
- [Infrastructure](./infra/README.md) - Docker Compose services
