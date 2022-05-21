.DEFAULT_GOAL := help


.PHONY: help
help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


.PHONY: start
start: ## Starts the revealjs server
	@docker-compose up --build


.PHONY: dev
dev: ## Starts the revealjs server with a live reloader
	@docker-compose run revealjs /slides --watch