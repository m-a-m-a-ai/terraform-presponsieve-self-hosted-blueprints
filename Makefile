.PHONY: help fmt fmt-check validate lint security docs clean all

help: ## Show this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

fmt: ## Rewrite all Terraform files to canonical format.
	terraform fmt -recursive .

fmt-check: ## Fail if any Terraform file is not canonically formatted.
	terraform fmt -recursive -check -diff .

validate: ## Initialise and validate every module and example.
	@set -e; for d in modules/*/ examples/*/; do \
		echo "==> $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$d validate; \
	done

lint: ## Run tflint across the repository.
	tflint --recursive

security: ## Run trivy against the Terraform configuration.
	trivy config --severity HIGH,CRITICAL .

docs: ## Regenerate the variable tables in every module README.
	@set -e; for d in modules/*/; do \
		terraform-docs markdown table --output-file README.md --output-mode inject $$d; \
	done

all: fmt-check validate lint security ## Everything CI runs.

clean: ## Remove downloaded providers and lock files.
	find . -name '.terraform' -type d -prune -exec rm -rf {} +
	find . -name '.terraform.lock.hcl' -delete
