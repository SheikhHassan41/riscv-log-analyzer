# Makefile for riscv-log-analyzer

# Default target
all: report ## Run analyzer on all test log files and generate summaries

# Setup target: check required tools using setup_env.sh
setup: ## Check that all required tools (bash, grep, awk, etc.) are installed
	@./scripts/setup_env.sh

# Report target: generate summaries in output/
report: setup ## Generate a summary report in output/
	@./scripts/generate_report.sh

# Test target: run the analyzer on each test_data file and verify expected exit codes
test: setup ## Run the analyzer on each test_data file and verify expected output
	@echo "=== Running Automated Tests ==="
	@./scripts/analyze.sh test_data/sample_pass.log > /dev/null && echo "[PASS] sample_pass.log executed successfully (Exit 0)"
	@if ./scripts/analyze.sh test_data/sample_fail.log > /dev/null 2>&1; then \
		echo "[FAIL] sample_fail.log expected non-zero exit code"; exit 1; \
	else \
		echo "[PASS] sample_fail.log correctly returned failure exit code (Exit 1)"; \
	fi
	@if ./scripts/analyze.sh test_data/sample_sim.log > /dev/null 2>&1; then \
		echo "[FAIL] sample_sim.log expected non-zero exit code"; exit 1; \
	else \
		echo "[PASS] sample_sim.log correctly returned failure exit code (Exit 1)"; \
	fi
	@echo "==============================="

# Clean target: remove all generated output files
clean: ## Remove all generated output files
	rm -rf output/*
	@echo "Cleaned output directory."

# Help target: print all available targets with descriptions
help: ## Print all available targets with descriptions
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Declare non-file targets
.PHONY: all setup report test clean help
# Conflict change from feature branch

