# Strava Transform

dbt 1.9+ data transformations for Strava analytics using DuckDB.

## Model Architecture

```
┌─────────────┐    ┌─────────────────┐    ┌─────────────┐    ┌─────────────┐
│   Sources   │───►│    Staging      │───►│Intermediate │───►│    Marts    │
│ (strava_raw)│    │  (stg_strava__) │    │(int_strava__)│   │(fct/dim_)   │
└─────────────┘    └─────────────────┘    └─────────────┘    └─────────────┘
                                                                    │
                                                                    ▼
                                                            ┌─────────────┐
                                                            │  Reporting  │
                                                            │   (rpt_)    │
                                                            └─────────────┘
```

## Installation

```bash
make install  # Install Python dependencies
make deps     # Install dbt packages
```

## Configuration

### Configuration Files

| File              | Purpose                                  |
|-------------------|------------------------------------------|
| `dbt_project.yml` | Project settings, model materializations |
| `profiles.yml`    | Database connection settings             |
| `packages.yml`    | dbt package dependencies                 |

### Environment Variables

| Variable                | Description              | Default                     |
|-------------------------|--------------------------|-----------------------------|
| `DUCKDB_PATH`           | Path to source DuckDB    | `./strava_datastack.duckdb` |
| `DUCKDB_REPORTING_PATH` | Path to reporting DuckDB | `./strava_reporting.duckdb` |

## Makefile Targets

| Target                           | Description                      |
|----------------------------------|----------------------------------|
| `make install`                   | Install Python dependencies      |
| `make deps`                      | Install dbt packages             |
| `make run`                       | Run all dbt models               |
| `make run-select MODELS=<model>` | Run specific models              |
| `make build`                     | Build all models and run tests   |
| `make test`                      | Run dbt tests                    |
| `make compile`                   | Compile models without running   |
| `make debug`                     | Test database connection         |
| `make docs-generate`             | Generate documentation           |
| `make docs-serve`                | Serve docs on port 8081          |
| `make docs`                      | Generate and serve documentation |
| `make clean`                     | Clean build artifacts            |

## Model Layers

### Staging (`models/staging/strava/`)

Clean and rename raw source tables. Materialized as views.

| Model                                  | Grain                            | Source                                |
|----------------------------------------|----------------------------------|---------------------------------------|
| `stg_strava__activities`               | One row per activity             | `strava_raw.activities`               |
| `stg_strava__activity_streams`         | One row per activity/stream type | `strava_raw.activity_streams`         |
| `stg_strava__activity_zones`           | One row per activity/zone type   | `strava_raw.activity_zones`           |
| `stg_strava__activity_segment_efforts` | One row per segment effort       | `strava_raw.activity_segment_efforts` |
| `stg_strava__dlt_loads`                | One row per dlt load             | `strava_raw._dlt_loads`               |

### Intermediate (`models/intermediate/`)

Reshape and aggregate data. Materialized as views (except incremental models).

| Model                                | Grain                       | Description                             |
|--------------------------------------|-----------------------------|-----------------------------------------|
| `int_strava__activity_streams`       | One row per activity        | Pivoted stream types per activity       |
| `int_strava__activity_stream_points` | One row per activity/second | Unnested time-series data (incremental) |
| `int_strava__segments`               | One row per segment         | Aggregated segment information          |

### Marts (`models/marts/`)

Business-logic facts and dimensions. Materialized as tables.

| Model                              | Grain                       | Description                  |
|------------------------------------|-----------------------------|------------------------------|
| `fct_strava__activities`           | One row per activity        | Activity facts with metrics  |
| `fct_strava__segment_efforts`      | One row per segment effort  | Segment performance facts    |
| `fct_strava__activity_data_points` | One row per activity/second | Time-series data points      |
| `dim_strava__segments`             | One row per segment         | Segment dimension attributes |

### Reporting (`models/reporting/`)

Denormalized tables optimized for Evidence queries. Materialized as tables in a separate `reporting` database.

| Model                               | Purpose                         |
|-------------------------------------|---------------------------------|
| `rpt_kpis__all`                     | KPI calculations for dashboards |
| `rpt_streaks__all`                  | Activity streak analysis        |
| `rpt_activity_detail__activity`     | Detailed activity view          |
| `rpt_activity_zones__activity_zone` | Zone distribution analysis      |

## dbt Packages

| Package            | Version           | Purpose                 |
|--------------------|-------------------|-------------------------|
| `dbt_utils`        | >=1.3.0, <2.0.0   | Utility macros          |
| `dbt_expectations` | >=0.10.4, <0.11.0 | Data quality testing    |
| `codegen`          | >=0.13.1, <0.14.0 | Code generation helpers |

## Usage

### Run All Models

```bash
make run
```

### Run Specific Models

```bash
# Run a single model
make run-select MODELS=fct_strava__activities

# Run models with dependencies
make run-select MODELS=+fct_strava__activities

# Run a folder
make run-select MODELS=marts
```

### Testing

```bash
# Run all tests
make test

# Build and test
make build
```

### Documentation

```bash
# Generate and serve docs
make docs

# Or separately
make docs-generate
make docs-serve  # Opens on http://localhost:8081
```

## Project Configuration

Key settings from `dbt_project.yml`:

```yaml
models:
  strava_transform:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table
      +schema: marts
    reporting:
      +materialized: table
      +database: reporting
      +schema: reporting
```

The reporting models write to a separate DuckDB file (`strava_reporting.duckdb`) for use by Evidence dashboards.
