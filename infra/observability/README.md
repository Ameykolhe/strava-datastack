# Observability Stack

OpenTelemetry-based monitoring infrastructure for distributed tracing, metrics, and logging.

## Architecture

```
                                ┌─────────────────┐
                                │   Applications  │
                                │ (Airflow, dlt)  │
                                └────────┬────────┘
                                         │ OTLP
                                         ▼
                              ┌──────────────────────┐
                              │   OTEL Collector     │
                              │   (otel-collector)   │
                              └──────────┬───────────┘
                    ┌─────────────┬──────┴──────┬─────────────┐
                    │             │             │             │
                    ▼             ▼             ▼             ▼
             ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
             │  Jaeger  │  │Prometheus│  │   Loki   │  │ Promtail │
             │ (traces) │  │(metrics) │  │  (logs)  │  │(log ship)│
             └──────────┘  └──────────┘  └──────────┘  └──────────┘
                    │             │             │
                    └─────────────┴──────┬──────┘
                                         ▼
                              ┌──────────────────────┐
                              │       Grafana        │
                              │    (dashboards)      │
                              └──────────────────────┘
```

## Services

| Service          | Port                     | Image                                         | Description                 |
|------------------|--------------------------|-----------------------------------------------|-----------------------------|
| `otel-collector` | 4317 (gRPC), 4318 (HTTP) | `otel/opentelemetry-collector-contrib:0.96.0` | Central telemetry hub       |
| `jaeger`         | 16686                    | `jaegertracing/all-in-one:1.54`               | Distributed tracing UI      |
| `elasticsearch`  | 9200                     | `elasticsearch:8.12.0`                        | Trace storage backend       |
| `prometheus`     | 9090                     | `prom/prometheus:v2.50.0`                     | Metrics storage and queries |
| `loki`           | 3100                     | `grafana/loki:2.9.4`                          | Log aggregation             |
| `promtail`       | -                        | `grafana/promtail:2.9.4`                      | Log shipping agent          |
| `grafana`        | 3000                     | `grafana/grafana:10.3.3`                      | Visualization dashboards    |

## Configuration Files

| File                                | Purpose                                       |
|-------------------------------------|-----------------------------------------------|
| `config/otel-collector-config.yaml` | OTEL collector pipelines                      |
| `config/prometheus.yml`             | Prometheus scrape configuration               |
| `config/loki-config.yaml`           | Loki storage and ingestion                    |
| `config/promtail-config.yaml`       | Log file discovery and labels                 |
| `config/grafana/provisioning/`      | Grafana datasource and dashboard provisioning |

## OTEL Collector Pipelines

The collector receives telemetry via OTLP and routes to backends:

### Traces Pipeline

```yaml
traces:
  receivers: [ otlp ]
  processors: [ memory_limiter, batch, resource ]
  exporters: [ otlp/jaeger ]
```

Traces are exported to Jaeger via OTLP (gRPC).

### Metrics Pipeline

```yaml
metrics:
  receivers: [ otlp, prometheus ]
  processors: [ memory_limiter, batch, resource ]
  exporters: [ prometheusremotewrite ]
```

Metrics are exported to Prometheus via remote write.

### Logs Pipeline

```yaml
logs:
  receivers: [ otlp ]
  processors: [ memory_limiter, resource, transform/logs, batch ]
  exporters: [ loki ]
```

Logs are enriched with trace/span IDs and exported to Loki.

## Accessing Services

### Grafana

- URL: http://localhost:3000
- Default credentials: `admin` / `admin`
- Pre-configured datasources: Prometheus, Loki, Jaeger

### Jaeger

- URL: http://localhost:16686
- Search traces by service, operation, tags
- View trace timelines and spans

### Prometheus

- URL: http://localhost:9090
- Query metrics with PromQL
- View targets and alerts

### Loki (via Grafana)

- Access through Grafana Explore
- Query logs with LogQL
- Correlate with traces via trace ID

## Sending Telemetry

Applications send telemetry to the OTEL collector:

### HTTP Endpoint

```
http://otel-collector:4318/v1/traces
http://otel-collector:4318/v1/metrics
http://otel-collector:4318/v1/logs
```

### gRPC Endpoint

```
otel-collector:4317
```

### Environment Variables

Configure applications to send telemetry:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_SERVICE_NAME=my-service
OTEL_RESOURCE_ATTRIBUTES=service.namespace=strava-datastack
```

## Resource Attributes

The collector adds standard attributes to all telemetry:

| Attribute                | Value                     | Description       |
|--------------------------|---------------------------|-------------------|
| `service.namespace`      | `strava-datastack`        | Project namespace |
| `deployment.environment` | From `STRAVA_ENVIRONMENT` | Environment name  |

## Log Correlation

The `transform/logs` processor enriches logs with trace context:

```yaml
transform/logs:
  log_statements:
    - context: log
      statements:
        - set(attributes["trace_id"], trace_id)
        - set(attributes["span_id"], span_id)
```

This enables clicking from logs to traces in Grafana.

## Environment Variables

Copy `.env.example` to `.env` to configure credentials:

```bash
cp .env.example .env
```

| Variable                 | Description            | Default |
|--------------------------|------------------------|---------|
| `GRAFANA_ADMIN_USER`     | Grafana admin username | `admin` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | `admin` |

## Data Retention

| Service       | Retention    | Configuration                       |
|---------------|--------------|-------------------------------------|
| Prometheus    | 15 days      | `--storage.tsdb.retention.time=15d` |
| Elasticsearch | Default      | Jaeger index lifecycle              |
| Loki          | Configurable | `loki-config.yaml`                  |
