.PHONY: help

help:
	@echo "Strava Datastack - Multi-project Makefile"
	@echo ""
	@echo "This project consists of 4 independent sub-projects:"
	@echo "  - extract/    : Data extraction pipeline"
	@echo "  - transform/  : dbt transformations"
	@echo "  - visualize/  : Evidence dashboards"
	@echo "  - airflow/    : Apache Airflow orchestration"
	@echo ""
	@echo "Common targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Sub-project specific targets:"
	@echo "  Use 'make -C <project>' to run targets in specific projects:"
	@echo "    make -C extract help"
	@echo "    make -C transform help"
	@echo "    make -C visualize help"
	@echo "    make -C airflow help"

.DEFAULT_GOAL := help