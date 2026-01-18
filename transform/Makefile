.PHONY: help install run test clean docs docs-generate docs-serve

help:  ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies
	uv sync

deps:  ## Install dbt packages
	dbt deps

run:  ## Run all dbt models
	dbt run

run-select:  ## Run specific models (e.g., make run-select MODELS=stg_strava_activities)
	dbt run --select $(MODELS)

build:  ## Build all models and run tests
	dbt build

test:  ## Run dbt tests
	dbt test

seed:  ## Load seed data
	dbt seed

snapshot:  ## Run snapshots
	dbt snapshot

compile:  ## Compile dbt models
	dbt compile

debug:  ## Debug dbt connection
	dbt debug

docs-generate:  ## Generate dbt documentation
	dbt docs generate

docs-serve:  ## Serve dbt documentation on port 8081
	dbt docs serve --port 8081

docs:  ## Generate and serve dbt documentation
	@$(MAKE) docs-generate
	@$(MAKE) docs-serve

clean:  ## Clean build artifacts
	rm -rf target/ dbt_packages/ logs/

.DEFAULT_GOAL := help