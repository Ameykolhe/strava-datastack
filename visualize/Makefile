.PHONY: help install dev build test preview sources clean

help:  ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:  ## Install dependencies
	npm install

dev:  ## Start development server
	npm run dev

build:  ## Build for production
	npm run build

build-strict:  ## Build with strict mode
	npm run build:strict

test:  ## Run tests
	npm run test

preview:  ## Preview production build
	npm run preview

sources:  ## Validate data sources
	npm run sources

sources-strict:  ## Validate sources with strict mode
	npm run sources:strict

clean:  ## Clean build artifacts and node_modules
	rm -rf node_modules/ .evidence/

.DEFAULT_GOAL := help