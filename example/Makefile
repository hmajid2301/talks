.DEFAULT_GOAL := help


.PHONY: help
help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


.PHONY: build
build: ## Builds the Docker images needed by our app
	@docker compose build --ssh default --no-cache


.PHONY: start
start: build ## Starts the FastAPI web service
	@docker compose up


.PHONY: lint
lint: build ## Runs the lint jobs
	@docker compose run --rm app pre-commit run --all-files


.PHONY: test
test: build ## Runs the tests
	@docker compose run --rm app pytest
