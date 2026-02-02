.PHONY: help trigger

INFRA_COMPOSE_FILE := ../infra/docker-compose.yml
COMPOSE := docker compose -f $(INFRA_COMPOSE_FILE) --profile airflow

help:  ## Show this help message
	@echo "Airflow Docker Compose Management"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

trigger:  ## Trigger pipeline (optional dates: make trigger START_DATE=2024-01-01 END_DATE=2024-12-31)
	@if [ -n "$(START_DATE)" ] && [ -z "$(END_DATE)" ]; then \
		echo "END_DATE is required when START_DATE is set"; \
		exit 1; \
	fi
	@if [ -n "$(END_DATE)" ] && [ -z "$(START_DATE)" ]; then \
		echo "START_DATE is required when END_DATE is set"; \
		exit 1; \
	fi
	@if [ -n "$(START_DATE)" ] && [ -n "$(END_DATE)" ]; then \
		echo "Triggering pipeline for date range: $(START_DATE) to $(END_DATE)..."; \
		$(COMPOSE) exec airflow-worker airflow dags trigger strava_data_pipeline \
			--conf '{"start_date": "$(START_DATE)", "end_date": "$(END_DATE)"}'; \
	else \
		echo "Triggering pipeline with default dates..."; \
		$(COMPOSE) exec airflow-worker airflow dags trigger strava_data_pipeline; \
	fi

.DEFAULT_GOAL := help
