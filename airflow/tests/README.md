# Airflow Tests

This directory contains test suites for the Strava Data Pipeline Airflow DAGs and operators.

## Test Structure

```
tests/
├── dags/
│   └── test_dag_integrity.py      # DAG structure and configuration tests
├── operators/
│   └── test_strava_extract_operator.py  # Custom operator tests
├── test_pipeline_integration.py   # End-to-end pipeline tests
├── conftest.py                    # Shared pytest fixtures
└── pytest.ini                     # Pytest configuration
```

## Test Categories

### 1. DAG Integrity Tests (`test_dag_integrity.py`)
Tests that verify:
- No import errors in DAGs
- Correct number of DAGs
- DAG configuration (tags, retries, schedules)
- Task dependencies and execution order
- Pool configuration for sequential DuckDB execution
- Retry and timeout configurations

### 2. Operator Tests (`test_strava_extract_operator.py`)
Tests for the custom `StravaExtractOperator`:
- Operator initialization
- Template field configuration
- Credential handling and validation
- Successful execution scenarios
- Error handling and cleanup
- Date parameter handling (None, "None", empty strings)

### 3. Integration Tests (`test_pipeline_integration.py`)
End-to-end tests that verify:
- Complete pipeline structure
- Task execution order
- Sequential execution configuration for DuckDB
- Configuration handling (dates, retries, timeouts)
- Proper pool usage for preventing lock conflicts

## Running Tests

### Prerequisites

Install pytest and dependencies:

```bash
pip install pytest pytest-mock
```

### Run All Tests

```bash
# From the airflow directory
cd /path/to/strava-datastack/airflow
python -m pytest tests/ -v
```

### Run Specific Test Suites

```bash
# DAG integrity tests only
python -m pytest tests/dags/test_dag_integrity.py -v

# Operator tests only
python -m pytest tests/operators/test_strava_extract_operator.py -v

# Integration tests only
python -m pytest tests/test_pipeline_integration.py -v
```

### Run with Coverage

```bash
python -m pytest tests/ --cov=dags --cov=plugins --cov-report=html
```

### Run Tests in Docker

```bash
# Install pytest in the Airflow worker container
docker compose exec airflow-worker pip install --user pytest pytest-mock

# Run tests
docker compose exec airflow-worker python -m pytest /opt/airflow/tests/ -v
```

## Test Markers

Tests are categorized with markers:
- `@pytest.mark.unit` - Unit tests for individual components
- `@pytest.mark.integration` - Integration tests
- `@pytest.mark.slow` - Tests that take longer to run

Run tests by marker:
```bash
python -m pytest tests/ -m unit  # Run only unit tests
python -m pytest tests/ -m "not slow"  # Skip slow tests
```

## Expected Test Results

All tests should pass when:
1. DAGs are properly structured
2. Environment variables are set (for operator tests)
3. The database schema is correct
4. Pool `dbt_duckdb_pool` is configured in Airflow

## Troubleshooting

### Import Errors

If you see import errors:
```bash
# Ensure AIRFLOW_HOME is set
export AIRFLOW_HOME=/path/to/airflow

# Ensure DAGs folder is in path
export AIRFLOW__CORE__DAGS_FOLDER=/path/to/airflow/dags
```

### Missing Dependencies

```bash
pip install -r requirements.txt
pip install pytest pytest-mock
```

### DAG Load Failures

Check for syntax errors:
```bash
python -m py_compile dags/*.py
```

## Continuous Integration

These tests can be integrated into CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Run Airflow Tests
  run: |
    pip install pytest pytest-mock
    pytest tests/ -v
```