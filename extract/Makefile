.PHONY: help install test lint format clean run

help:  ## Show this help message
	@echo "Strava Extract Pipeline"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies
	uv sync

install-dev:  ## Install development dependencies
	uv sync --all-extras

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

run:  ## Run pipeline (optional: make run START_DATE=2024-01-01 END_DATE=2024-12-31 DEBUG=1)
	@if [ -n "$(START_DATE)" ] && [ -z "$(END_DATE)" ]; then \
		echo "END_DATE is required when START_DATE is set"; \
		exit 1; \
	fi
	@if [ -n "$(END_DATE)" ] && [ -z "$(START_DATE)" ]; then \
		echo "START_DATE is required when END_DATE is set"; \
		exit 1; \
	fi
	@if [ -n "$(START_DATE)" ] && [ -n "$(END_DATE)" ]; then \
		echo "Running pipeline for date range: $(START_DATE) to $(END_DATE)$(if $(DEBUG), with DEBUG logging,)..."; \
		python -m strava_extract --start-date $(START_DATE) --end-date $(END_DATE) $(if $(DEBUG),--log-level DEBUG,); \
	else \
		echo "Running pipeline with default dates (last 30 days)$(if $(DEBUG), with DEBUG logging,)..."; \
		python -m strava_extract $(if $(DEBUG),--log-level DEBUG,); \
	fi

.DEFAULT_GOAL := help
