# dbt Transform Tests

This directory contains test suites for the dbt transformation models.

## Test Structure

### Schema Tests (in model `.yml` files)
Located alongside models in `models/`:
- `models/core/fct_activities.yml` - Tests for activity fact table
- `models/core/fct_activity_data_points.yml` - Tests for time-series data points
- `models/core/fct_activity_zones.yml` - Tests for activity zones
- `models/staging/strava/*.yml` - Tests for staging models

### Custom Tests (in `tests/` directory)
```
tests/
├── test_activity_data_consistency.sql      # Activity data validation
├── test_stream_data_consistency.sql        # Stream data validation
└── test_variable_schema_handling.sql       # Variable schema handling
```

## Test Categories

### 1. Schema Tests
Built-in dbt tests defined in YAML:
- **Unique**: Primary keys and unique identifiers
- **Not Null**: Required fields
- **Relationships**: Foreign key constraints
- **Accepted Values**: Enum validations
- **Expression Tests**: Custom business logic validations

### 2. Data Quality Tests

#### Activity Data Consistency (`test_activity_data_consistency.sql`)
Validates:
- Moving time ≤ Elapsed time
- Non-negative distances
- Non-negative speeds
- Reasonable heart rate values (30-250 bpm)
- Non-negative power values
- Future dates are rejected

#### Stream Data Consistency (`test_stream_data_consistency.sql`)
Validates:
- Non-negative time and distance values
- Valid GPS coordinates (-90 to 90 latitude, -180 to 180 longitude)
- Reasonable heart rate (0-300 bpm)
- Valid altitude (-500m to 9000m)
- Valid grade (-100% to 100%)

#### Variable Schema Handling (`test_variable_schema_handling.sql`)
Validates:
- Models handle activities with/without heart rate data
- Models handle activities with/without power data
- Optional sensor fields are properly handled
- No parsing errors for variable schemas

## Test Coverage

### Models Tested
✅ `fct_activities` - 20+ tests including:
- Primary key uniqueness
- Required field validation
- Activity type validation
- Distance/speed/elevation validations
- Heart rate and power range checks
- Foreign key relationships

✅ `fct_activity_data_points` - 15+ tests including:
- Unique data point IDs
- Foreign key to activities
- Non-negative values (time, distance, velocity)
- GPS coordinate validations
- Heart rate and altitude validations
- Stream index validations

✅ `fct_activity_zones` - Basic schema tests

✅ Staging models - Comprehensive coverage

## Running Tests

### Run All Tests

```bash
cd /path/to/transform
dbt test --profile strava_transform --target dev
```

### Run Tests for Specific Model

```bash
# Test a single model
dbt test --select fct_activities

# Test a model and its dependencies
dbt test --select +fct_activities+
```

### Run Specific Test Types

```bash
# Run only schema tests
dbt test --exclude test_type:singular

# Run only custom tests
dbt test --select test_type:singular

# Run tests with warnings as errors
dbt test --warn-error
```

### Run Tests by Tag

```bash
# Run tests for core models only
dbt test --select tag:core
```

## Test Results

### Expected Results
When running against the Airflow-generated database:
- **127 of 128 tests should pass**
- 1 expected failure: `location_country` not_null (this field is optional in Strava data)

### Test Output

```
Finished running 128 data tests in 2.02s
Done. PASS=127 WARN=0 ERROR=1 SKIP=0 TOTAL=128
```

## Understanding Test Failures

### Common Failures and Solutions

#### 1. Column Not Found Errors
```
Binder Error: Referenced column "X" not found
```
**Solution**: This may indicate variable schema issues. Check that `safe_column()` macro is used for optional fields.

#### 2. Data Range Violations
```
Test failed: 5 records violate constraint
```
**Solution**: Check the test's WHERE clause and severity. Some tests are warnings for outliers.

#### 3. Relationship Test Failures
```
Foreign key violation: X records not found in parent table
```
**Solution**: Ensure parent tables are built before child tables (check model dependencies).

## Test Severity

Tests can have different severity levels:

```yaml
tests:
  - expression_is_true:
      expression: "hr_avg between 30 and 250"
      config:
        severity: warn  # Log warning but don't fail
```

- `error` (default): Test failure stops execution
- `warn`: Test failure logs warning but continues

## Writing New Tests

### Adding Schema Tests

Edit the model's `.yml` file:

```yaml
models:
  - name: my_model
    columns:
      - name: my_column
        tests:
          - unique
          - not_null
          - accepted_values:
              values: ['A', 'B', 'C']
```

### Adding Custom Tests

Create a new `.sql` file in `tests/`:

```sql
-- tests/test_my_validation.sql
with my_model as (
    select * from {{ ref('my_model') }}
)

select *
from my_model
where some_condition_that_should_not_be_true
```

## Continuous Testing

Run tests automatically:

```bash
# After every model build
dbt build  # Runs models AND tests

# In CI/CD pipeline
dbt test --fail-fast  # Stop on first failure
```

## Test Documentation

Generate documentation including test coverage:

```bash
dbt docs generate
dbt docs serve
```

This creates an interactive documentation site showing all tests.