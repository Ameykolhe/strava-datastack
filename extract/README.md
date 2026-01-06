# Strava Extract - Production-Ready Data Extraction Pipeline

A well-structured, production-ready Python package for extracting Strava activity data using dlt (Data Load Tool).

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development](#development)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Features

- **Type-safe configuration** with Pydantic and YAML
- **Modular architecture** with clean separation of concerns
- **Thread-safe rate limiting** (95 requests per 15 minutes)
- **Automatic OAuth2 token refresh**
- **Incremental loading** with state management
- **Structured logging** (JSON or text formats)
- **Comprehensive error handling** with fail-fast approach
- **Full test coverage** with pytest
- **Production-ready** with proper packaging and dependency management

## Project Structure

```
extract/
├── src/strava_extract/          # Main package
│   ├── config/                  # Configuration management
│   │   ├── settings.py          # Pydantic settings (type-safe)
│   │   ├── config.yaml          # Non-secret configuration
│   │   └── resources.yaml       # API resource definitions
│   ├── auth/                    # Authentication
│   │   └── oauth.py             # OAuth2 with token refresh
│   ├── client/                  # API client components
│   │   ├── rate_limiter.py      # Thread-safe rate limiting
│   │   └── paginator.py         # Rate-limited pagination
│   ├── sources/                 # DLT sources
│   │   └── strava_source.py     # DLT source definition
│   ├── utils/                   # Utilities
│   │   ├── logging.py           # Structured logging
│   │   ├── exceptions.py        # Custom exceptions
│   │   └── validators.py        # Input validation
│   ├── __main__.py              # CLI entry point
│   └── pipeline.py              # Pipeline orchestration
├── tests/                       # Test suite
│   ├── conftest.py              # Pytest fixtures
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── e2e/                     # End-to-end tests
├── config/                      # Configuration files
│   ├── config.yaml              # Default configuration
│   ├── config.prod.yaml         # Production overrides
│   └── resources.yaml           # API endpoint definitions
├── .env                         # Secrets (not committed)
├── .env.example                 # Example secrets file
├── Makefile                     # Common commands
└── pytest.ini                   # Pytest configuration
```

## Installation

### Prerequisites

- **Python 3.11+**
- **uv package manager** (recommended) or pip
- **Strava API credentials** (see Configuration section)

### Install Dependencies

```bash
# From project root
uv sync

# Or install dev dependencies
uv sync --all-extras
```

## Configuration

### 1. Set Up Strava API Credentials

1. Go to https://www.strava.com/settings/api
2. Create a new application
3. Note your `client_id` and `client_secret`
4. Generate a refresh token with proper scopes (see main project SETUP.md)

### 2. Create .env File

```bash
cp extract/.env.example extract/.env
```

Edit `extract/.env` and fill in your credentials:

```bash
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_secret
STRAVA_REFRESH_TOKEN=your_refresh_token
```

### 3. Adjust Configuration (Optional)

Edit `extract/config/config.yaml` to customize:

- API settings (timeouts, retries)
- Rate limiting (requests per period)
- Logging (level, format)
- Pipeline settings (destination, dataset name)

## Usage

### Basic Usage

```bash
# Extract last 30 days (default)
python -m strava_extract

# Or use the helper script
./extract/scripts/run_pipeline.sh

# Or use make
make -C extract run
```

### Advanced Usage

```bash
# Extract specific date range
python -m strava_extract --start-date 2024-01-01 --end-date 2024-12-31

# With debug logging
python -m strava_extract --log-level DEBUG

# Use custom config file
STRAVA_CONFIG_PATH=/path/to/config.yaml python -m strava_extract

# Backfill historical data
python -m strava_extract --start-date 2020-01-01
```

### Programmatic Usage

```python
from strava_extract import run_pipeline, StravaPipeline

# Simple usage
load_info = run_pipeline(start_date="2024-01-01", end_date="2024-12-31")

# Advanced usage with custom pipeline
pipeline = StravaPipeline(start_date="2024-01-01")
load_info = pipeline.run()
```

## Development

### Code Quality Tools

```bash
# Format code
make -C extract format

# Run linters
make -C extract lint

# Run all checks (format, lint, test)
make -C extract check
```

### Project Structure Best Practices

The project follows Python best practices:

1. **Separation of Concerns**: Each module has a single responsibility
2. **Type Hints**: All functions have proper type annotations
3. **Docstrings**: Comprehensive documentation for all public APIs
4. **Error Handling**: Custom exceptions with contextual error messages
5. **Configuration Management**: Type-safe settings with Pydantic
6. **Logging**: Structured logging with trace IDs for request correlation

## Testing

### Run Tests

```bash
# All tests
make -C extract test

# Unit tests only
make -C extract test-unit

# Integration tests only
make -C extract test-integration

# With coverage report
make -C extract test-coverage
```

### Test Structure

- **Unit Tests** (`tests/unit/`): Test individual components in isolation
- **Integration Tests** (`tests/integration/`): Test component interactions
- **E2E Tests** (`tests/e2e/`): Test full pipeline with mocked API

### Writing Tests

```python
import pytest
from strava_extract.client.rate_limiter import RateLimiter

def test_rate_limiter(rate_limiter):
    # Test implementation
    assert rate_limiter.max_requests == 5
```

## Troubleshooting

### Common Issues

#### Missing Credentials Error

```
ERROR: Missing required credentials...
```

**Solution**: Ensure your `.env` file exists and contains all required variables:
- `STRAVA_CLIENT_ID`
- `STRAVA_CLIENT_SECRET`
- `STRAVA_REFRESH_TOKEN`

#### Configuration File Not Found

```
ConfigurationError: Configuration file not found
```

**Solution**: Make sure you're running the command from the project root or set `STRAVA_CONFIG_PATH` environment variable.

#### Rate Limit Exceeded

The pipeline will automatically wait when rate limits are hit (95 requests per 15 minutes). You'll see a progress bar during the wait period.

#### Authentication Failures

If OAuth token refresh fails, check that:
1. Your refresh token is valid and has correct scopes
2. Client ID and secret are correct
3. You have internet connectivity

### Debugging

Enable debug logging for detailed information:

```bash
python -m strava_extract --log-level DEBUG
```

Check logs for trace IDs to correlate related log entries:

```
2026-01-06 17:12:52 - strava_extract.pipeline - INFO - Pipeline initialized with trace_id=2c5ad92b-b71b-478b-8d89-1f9c0277cafd
```

## Architecture

### Data Flow

```
User Input → Validation
    ↓
Config Loading → Settings (Pydantic)
    ↓
Authentication → OAuth2 Token Refresh
    ↓
API Requests → Rate Limiting → Pagination
    ↓
DLT Source → Incremental Loading
    ↓
DuckDB Storage
```

### Key Components

- **`config/settings.py`**: Type-safe configuration using Pydantic
- **`auth/oauth.py`**: OAuth2 implementation with automatic token refresh
- **`client/rate_limiter.py`**: Thread-safe rate limiting
- **`client/paginator.py`**: Custom paginator with rate limit integration
- **`sources/strava_source.py`**: DLT source with resource definitions
- **`pipeline.py`**: Main orchestration with error handling

### Configuration Hierarchy

Configuration is loaded in this order (later overrides earlier):

1. `config/config.yaml` - Default values
2. `config/config.prod.yaml` - Production overrides (if exists)
3. Environment variables - `STRAVA__*` prefixed variables
4. `.env` file - Secrets and local overrides

## Migration from Legacy Code

The new structure maintains backward compatibility:

- **Same DLT pipeline name**: `strava_datastack`
- **Same destination**: DuckDB
- **Same state management**: Uses `.dlt/` directory
- **Same CLI interface**: `--start-date` and `--end-date` flags

### Key Improvements

1. **Modular**: Code split into focused, testable modules
2. **Type-safe**: Pydantic models validate configuration
3. **Testable**: Comprehensive test suite with 80%+ coverage
4. **Maintainable**: Clear separation of concerns
5. **Production-ready**: Proper error handling, logging, and monitoring

## Contributing

### Code Style

- Follow PEP 8
- Use type hints for all functions
- Write docstrings for public APIs
- Keep functions focused and small
- Use meaningful variable names

### Pull Request Process

1. Create feature branch
2. Write tests for new functionality
3. Ensure all tests pass (`make check`)
4. Update documentation
5. Submit pull request

## License

See LICENSE file in project root.

## Support

For issues or questions:
1. Check this README and main project SETUP.md
2. Review error messages and logs (with trace IDs)
3. Check test examples for usage patterns
4. File an issue with reproduction steps and logs
