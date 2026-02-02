# Airflow Infrastructure

Apache Airflow 3.x services with CeleryExecutor for the Strava data pipeline.

## Services

| Service                 | Port | Description                          |
|-------------------------|------|--------------------------------------|
| `airflow-apiserver`     | 8080 | REST API and web UI                  |
| `airflow-scheduler`     | -    | DAG scheduling                       |
| `airflow-worker`        | -    | Celery task execution                |
| `airflow-triggerer`     | -    | Async trigger handling               |
| `airflow-dag-processor` | -    | DAG parsing and processing           |
| `airflow-db`            | -    | PostgreSQL metadata database         |
| `redis`                 | 6379 | Celery message broker                |
| `flower`                | 5555 | Celery monitoring (optional profile) |

## Dockerfile

The custom Airflow image (`Dockerfile`) extends the official image:

```dockerfile
FROM apache/airflow:3.1.5

# Create data directory for DuckDB
RUN mkdir -p /opt/airflow/data && chown -R airflow:root /opt/airflow/data

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Custom entrypoint for extract package installation
ENTRYPOINT ["/custom-entrypoint.sh"]
```

### Key Dependencies

| Package                                | Purpose                     |
|----------------------------------------|-----------------------------|
| `astronomer-cosmos`                    | dbt integration for Airflow |
| `dbt-core`, `dbt-duckdb`               | dbt transformations         |
| `dlt[duckdb]`                          | Data extraction pipeline    |
| `apache-airflow-providers-openlineage` | Lineage tracking            |
| `opentelemetry-*`                      | Distributed tracing         |

## Configuration

### Environment Variables

Core Airflow settings from `docker-compose.yml`:

| Variable                              | Value            | Description                |
|---------------------------------------|------------------|----------------------------|
| `AIRFLOW__CORE__EXECUTOR`             | `CeleryExecutor` | Distributed task execution |
| `AIRFLOW__CORE__LOAD_EXAMPLES`        | `false`          | Disable example DAGs       |
| `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` | PostgreSQL URI   | Metadata database          |
| `AIRFLOW__CELERY__BROKER_URL`         | Redis URI        | Task queue                 |

Observability settings:

| Variable                          | Description                                |
|-----------------------------------|--------------------------------------------|
| `AIRFLOW__OPENLINEAGE__NAMESPACE` | OpenLineage namespace (`strava-datastack`) |
| `AIRFLOW__OPENLINEAGE__TRANSPORT` | Marquez HTTP endpoint                      |
| `AIRFLOW__METRICS__OTEL_ON`       | Enable OTEL metrics                        |
| `AIRFLOW__TRACES__OTEL_ON`        | Enable OTEL traces                         |
| `AIRFLOW__METRICS__OTEL_HOST`     | OTEL collector host                        |

Application settings:

| Variable                | Default                                     | Description        |
|-------------------------|---------------------------------------------|--------------------|
| `DUCKDB_PATH`           | `/opt/airflow/data/strava_datastack.duckdb` | Main database      |
| `DUCKDB_REPORTING_PATH` | `/opt/airflow/data/strava_reporting.duckdb` | Reporting database |
| `STRAVA_ENVIRONMENT`    | `production`                                | Environment name   |

### Volume Mounts

| Container Path           | Host Path               | Purpose               |
|--------------------------|-------------------------|-----------------------|
| `/opt/airflow/dags`      | `../../airflow/dags`    | DAG definitions       |
| `/opt/airflow/plugins`   | `../../airflow/plugins` | Custom operators      |
| `/opt/airflow/extract`   | `../../extract`         | Extract pipeline code |
| `/opt/airflow/transform` | `../../transform`       | dbt project           |
| `/opt/airflow/data`      | `./data`                | DuckDB databases      |
| `/opt/airflow/logs`      | `./logs`                | Airflow logs          |
| `/opt/airflow/config`    | `./config`              | Airflow config        |

## Usage

### Start Airflow

```bash
cd infra
docker compose --profile airflow up -d
```

### Access Web UI

Open http://localhost:8080

Default credentials: `airflow` / `airflow`

### View Logs

```bash
# All Airflow services
docker compose logs -f airflow-apiserver airflow-scheduler airflow-worker

# Specific service
docker compose logs -f airflow-worker
```

### Run Airflow CLI Commands

```bash
docker compose exec airflow-worker airflow dags list
docker compose exec airflow-worker airflow tasks list strava_data_pipeline
```

### Rebuild Image

```bash
docker compose --profile airflow build
docker compose --profile airflow up -d
```

## Integrations

### Cosmos (dbt)

The [astronomer-cosmos](https://astronomer.github.io/astronomer-cosmos/) package enables native dbt integration:

- Automatic DAG generation from dbt projects
- Task-level lineage and logging
- dbt test integration

### OpenLineage (Marquez)

Lineage events are sent to Marquez via the OpenLineage provider:

- Dataset-level lineage tracking
- Job run metadata
- Column-level lineage (when available)

### OpenTelemetry

Metrics and traces are exported to the OTEL collector:

- Task execution metrics
- DAG run traces
- Worker performance monitoring
