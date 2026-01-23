.PHONY: help build init up down restart logs clean credentials trigger test-connection refresh-dags

help:  ## Show this help message
	@echo "Airflow Docker Compose Management"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build:  ## Build custom Airflow Docker image
	@echo "Building custom Airflow image..."
	docker compose build

init:  ## Initialize Airflow database and create admin user
	@echo "Initializing Airflow database..."
	@echo "This will create default user: airflow / airflow"
	docker compose up airflow-init

up:  ## Start all Airflow services
	@echo "Starting Airflow services..."
	docker compose up -d
	@echo ""
	@echo "Airflow is starting up..."
	@echo "Web UI will be available at: http://localhost:8080"
	@echo "Default credentials: airflow / airflow"
	@echo ""
	@echo "Run 'make logs' to follow the logs"
	@echo "Run 'make credentials' to set up Strava credentials"

down:  ## Stop all Airflow services
	@echo "Stopping Airflow services..."
	docker compose down

restart:  ## Restart all Airflow services
	@echo "Restarting Airflow services..."
	docker compose restart

logs:  ## Follow Airflow logs (all services)
	docker compose logs -f

logs-scheduler:  ## Follow scheduler logs only
	docker compose logs -f airflow-scheduler

logs-worker:  ## Follow worker logs only
	docker compose logs -f airflow-worker

logs-webserver:  ## Follow webserver logs only
	docker compose logs -f airflow-webserver

credentials:  ## Set up Strava credentials in Airflow
	@echo "Setting up Strava credentials from ../extract/.env..."
	@if [ ! -f ../extract/.env ]; then \
		echo "Error: ../extract/.env not found"; \
		echo "Please create it first with your Strava credentials"; \
		exit 1; \
	fi
	@bash scripts/create-connections.sh

trigger:  ## Trigger the Strava pipeline (last 30 days)
	@echo "Triggering strava_data_pipeline DAG..."
	docker compose exec airflow-worker airflow dags trigger strava_data_pipeline
	@echo ""
	@echo "Pipeline triggered! View progress at: http://localhost:8080"

trigger-dates:  ## Trigger pipeline with custom dates (usage: make trigger-dates START=2024-01-01 END=2024-12-31)
	@if [ -z "$(START)" ] || [ -z "$(END)" ]; then \
		echo "Usage: make trigger-dates START=2024-01-01 END=2024-12-31"; \
		exit 1; \
	fi
	@echo "Triggering pipeline for date range: $(START) to $(END)..."
	docker compose exec airflow-worker airflow dags trigger strava_data_pipeline \
		--conf '{"start_date": "$(START)", "end_date": "$(END)"}'

refresh-dags:  ## Refresh DAG parsing/serialization
	@echo "Refreshing DAGs..."
	docker compose exec airflow-scheduler airflow dags reserialize

test-connection:  ## Test DuckDB connection
	@echo "Testing DuckDB connection..."
	docker compose exec airflow-worker python -c "\
import duckdb; \
conn = duckdb.connect('/opt/airflow/data/strava_datastack.duckdb'); \
print('Connection successful!'); \
print('Tables:', conn.execute('SHOW TABLES').fetchall()); \
conn.close()"

shell:  ## Open a shell in the Airflow worker container
	docker compose exec airflow-worker bash

clean:  ## Remove all containers, volumes, and data (WARNING: destructive!)
	@echo "WARNING: This will remove all Airflow data and containers!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down --volumes --remove-orphans; \
		rm -rf logs/*; \
		rm -rf data/*; \
		echo "Cleanup complete!"; \
	else \
		echo "Aborted."; \
	fi

reset:  ## Reset Airflow (clean + init)
	@echo "Resetting Airflow environment..."
	$(MAKE) clean
	$(MAKE) build
	$(MAKE) up

ps:  ## Show status of all services
	docker compose ps

.DEFAULT_GOAL := help
