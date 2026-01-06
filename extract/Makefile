.PHONY: help install test lint format clean run

help:  ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies
	uv sync

install-dev:  ## Install development dependencies
	uv sync --all-extras

test:  ## Run all tests
	pytest tests/

test-unit:  ## Run unit tests only
	pytest tests/unit/ -m unit

test-integration:  ## Run integration tests only
	pytest tests/integration/ -m integration

test-e2e:  ## Run e2e tests only
	pytest tests/e2e/ -m e2e

test-coverage:  ## Run tests with HTML coverage report
	pytest --cov=strava_extract --cov-report=html --cov-report=term

lint:  ## Run linters
	ruff check src/
	mypy src/

format:  ## Format code
	black src/ tests/
	isort src/ tests/
	ruff check --fix src/ tests/

clean:  ## Clean build artifacts
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .coverage htmlcov build dist *.egg-info

run:  ## Run pipeline locally (default: last 30 days)
	python -m strava_extract

run-debug:  ## Run pipeline with debug logging
	python -m strava_extract --log-level DEBUG

run-backfill:  ## Run backfill (example: 2024 data)
	python -m strava_extract --start-date 2024-01-01 --end-date 2024-12-31

check:  ## Run all checks (format, lint, test)
	@echo "Running format check..."
	@black --check src/ tests/
	@isort --check src/ tests/
	@echo "Running linter..."
	@ruff check src/
	@echo "Running type checker..."
	@mypy src/
	@echo "Running tests..."
	@pytest tests/

.DEFAULT_GOAL := help
