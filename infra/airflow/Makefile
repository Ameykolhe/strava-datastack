.PHONY: help credentials

help:  ## Show this help message
	@echo "Airflow Infrastructure Management"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

credentials:  ## Set up Strava credentials in Airflow
	@./scripts/create-credentials.sh

.DEFAULT_GOAL := help