# Strava DataStack Infrastructure

Docker Compose orchestration for all infrastructure services.

## Architecture

The infrastructure is organized as a multi-compose setup with a root `docker-compose.yml` that includes service-specific
compose files:

```
infra/
├── docker-compose.yml       # Root compose (includes all sub-composes)
├── airflow/                 # Airflow services
│   └── docker-compose.yml
├── observability/           # Monitoring stack
│   └── docker-compose.yml
├── lineage/                 # Marquez data lineage
│   └── docker-compose.yml
└── strava-infra/            # Shared network
    └── docker-compose.yml
```

## Shared Network

All services communicate via the `strava-infra` Docker network:

```yaml
networks:
  strava-infra:
    name: strava-infra
```

## Usage

### Start Airflow Stack

```bash
cd infra
docker compose --profile airflow up -d
```

### Start All Services

```bash
docker compose --profile all up -d
```

### Stop Services

```bash
docker compose down
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f airflow-worker
```

### Rebuild After Changes

```bash
docker compose --profile airflow build
docker compose --profile airflow up -d
```

## Volume Persistence

| Volume               | Purpose                     |
|----------------------|-----------------------------|
| `airflow-db-volume`  | Airflow metadata PostgreSQL |
| `marquez-db-volume`  | Marquez lineage PostgreSQL  |
| `elasticsearch-data` | Jaeger trace storage        |
| `prometheus-data`    | Metrics storage             |
| `grafana-data`       | Dashboard configurations    |
| `loki-data`          | Log storage                 |

## Service URLs

| Service    | URL                    | Description              |
|------------|------------------------|--------------------------|
| Airflow    | http://localhost:8080  | Workflow orchestration   |
| Grafana    | http://localhost:3000  | Observability dashboards |
| Jaeger     | http://localhost:16686 | Distributed tracing      |
| Prometheus | http://localhost:9090  | Metrics queries          |
| Marquez    | http://localhost:3001  | Data lineage UI          |
| Flower     | http://localhost:5555  | Celery monitoring        |

## Subdirectory Documentation

- [Airflow](./airflow/README.md) - Airflow services and configuration
- [Observability](./observability/README.md) - Monitoring stack
- [Lineage](./lineage/README.md) - Marquez data lineage
