# Infra Compose

This folder contains Docker Compose stacks for infra services. Each app stack lives in its own
subfolder and can be run standalone, or you can run the aggregated root compose.

## Root orchestration

From repo root:

```bash
docker compose -f infra/docker-compose.yml --profile airflow up -d
```

Full stack (all profiles):

```bash
docker compose -f infra/docker-compose.yml --profile all up -d
```

If your Docker Compose version does not support `include:`, use multi-file compose:

```bash
docker compose \
  -f infra/airflow/docker-compose.yml \
  -f infra/observability/docker-compose.yml \
  -f infra/lineage/docker-compose.yml \
  -f infra/strava-infra/docker-compose.yml \
  up -d
```

## Run a single app stack

Run from the app directory to pick up the local `.env`:

```bash
cd infra/airflow

docker compose --profile airflow up -d
```

```bash
cd infra/observability

docker compose up -d
```

```bash
cd infra/lineage

docker compose up -d
```

## Environment variables

- Shared values live in `infra/.env` (currently only `STRAVA_ENVIRONMENT`).
- App-specific values live in each app folder:
  - `infra/airflow/.env`
  - `infra/observability/.env`
  - `infra/lineage/.env`

When using the root compose file, export any overrides in your shell or use `--env-file`.

## Health check URLs

- Airflow API: http://localhost:8080
- Grafana: http://localhost:3000
- Marquez UI: http://localhost:3001
- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686
