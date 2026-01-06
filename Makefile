.PHONY: help install install-all clean clean-all

help:  ## Show this help message
	@echo "Strava Datastack - Multi-project Makefile"
	@echo ""
	@echo "This project consists of 3 independent sub-projects:"
	@echo "  - extract/    : Data extraction pipeline"
	@echo "  - transform/  : dbt transformations"
	@echo "  - visualize/  : Evidence dashboards"
	@echo ""
	@echo "Common targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Sub-project specific targets:"
	@echo "  Use 'make -C <project>' to run targets in specific projects:"
	@echo "    make -C extract help"
	@echo "    make -C transform help"
	@echo "    make -C visualize help"

install-all:  ## Install dependencies for all projects
	@echo "Installing extract dependencies..."
	@cd extract && $(MAKE) install
	@echo ""
	@echo "Installing transform dependencies..."
	@cd transform && $(MAKE) install
	@echo ""
	@echo "Installing visualize dependencies..."
	@cd visualize && $(MAKE) install
	@echo ""
	@echo "All dependencies installed!"

# Individual project installs
install-extract:  ## Install extract dependencies
	cd extract && $(MAKE) install

install-transform:  ## Install transform dependencies
	cd transform && $(MAKE) install

install-visualize:  ## Install visualize dependencies
	cd visualize && $(MAKE) install

# Extract targets
extract:  ## Run data extraction pipeline
	cd extract && $(MAKE) run

extract-dev:  ## Run extraction with debug logging
	cd extract && $(MAKE) run-debug

# Transform targets
transform:  ## Run dbt transformations
	cd transform && $(MAKE) run

transform-test:  ## Run dbt tests
	cd transform && $(MAKE) test

transform-docs:  ## Generate and serve dbt docs
	cd transform && $(MAKE) docs

# Visualize targets
visualize:  ## Start Evidence development server
	cd visualize && $(MAKE) dev

visualize-build:  ## Build Evidence dashboard
	cd visualize && $(MAKE) build

# Pipeline execution
pipeline:  ## Run full pipeline: extract -> transform
	@echo "Running extraction..."
	@cd extract && $(MAKE) run
	@echo ""
	@echo "Running transformations..."
	@cd transform && $(MAKE) run
	@echo ""
	@echo "Pipeline complete!"

# Clean targets
clean-all:  ## Clean all build artifacts
	@echo "Cleaning extract..."
	@cd extract && $(MAKE) clean
	@echo "Cleaning transform..."
	@cd transform && $(MAKE) clean
	@echo "Cleaning visualize..."
	@cd visualize && $(MAKE) clean
	@echo "All projects cleaned!"

.DEFAULT_GOAL := help