.PHONY: help install run test clean docs docs-generate docs-serve

help:  ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies
	uv sync

deps:  ## Install dbt packages
	DUCKDB_PATH=../strava_datastack.duckdb dbt deps

run:  ## Run all dbt models
	DUCKDB_PATH=../strava_datastack.duckdb dbt run

run-select:  ## Run specific models (e.g., make run-select MODELS=stg_strava_activities)
	DUCKDB_PATH=../strava_datastack.duckdb dbt run --select $(MODELS)

build:  ## Build all models and run tests
	DUCKDB_PATH=../strava_datastack.duckdb dbt build

test:  ## Run dbt tests
	DUCKDB_PATH=../strava_datastack.duckdb dbt test

seed:  ## Load seed data
	DUCKDB_PATH=../strava_datastack.duckdb dbt seed

snapshot:  ## Run snapshots
	DUCKDB_PATH=../strava_datastack.duckdb dbt snapshot

compile:  ## Compile dbt models
	DUCKDB_PATH=../strava_datastack.duckdb dbt compile

debug:  ## Debug dbt connection
	DUCKDB_PATH=../strava_datastack.duckdb dbt debug

docs-generate:  ## Generate dbt documentation
	DUCKDB_PATH=../strava_datastack.duckdb dbt docs generate

docs-serve:  ## Serve dbt documentation on port 8081
	DUCKDB_PATH=../strava_datastack.duckdb dbt docs serve --port 8081

docs:  ## Generate and serve dbt documentation
	@$(MAKE) docs-generate
	@$(MAKE) docs-serve

clean:  ## Clean build artifacts
	rm -rf target/ dbt_packages/ logs/

.DEFAULT_GOAL := help