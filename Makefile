.DEFAULT_GOAL := help

.PHONY: help install test clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install Forge CLI to ~/.local/bin
	cd forge && bash install.sh

test: ## Run Forge self-tests
	bash forge/tests/run_all.sh

clean: ## Remove runtime artifacts
	rm -rf .forge/sessions/active/*.state .forge/hashes/*.hashes .forge/signals/*.done
	rm -rf forge/tests/tmp/
