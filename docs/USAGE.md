# RISC-V Log Analyzer - Detailed Usage Guide

## Core Scripts & Parameters

### 1. `scripts/analyze.sh`
The primary parsing and statistics engine. It reads simulation log files, extracts test results, calculates execution metrics using `awk`, and prints summaries.

* **Syntax:** `./scripts/analyze.sh <log_file> [options]`
* **Options:**
  * `--format [text|csv]`: Specifies output formatting. Choose `text` for a human-readable summary or `csv` for machine-parsable table rows (default: `text`).
  * `--output <path>`: Directs the output report to a specified file path instead of standard output (`stdout`). Automatically creates parent directories if needed.
  * `--verbose`: Enables verbose mode, printing individual test names and execution times as they are parsed.
  * `--help`: Displays the usage instructions and exits.

### 2. `scripts/setup_env.sh`
Performs an automated environment check to ensure all required command-line dependencies (`bash`, `grep`, `awk`, `sed`, `make`) are present and executable.

### 3. `scripts/generate_report.sh`
Scans the `test_data/` directory for log files and automatically batch-processes them into both text and CSV summary reports located inside the `output/` directory.

---

## Makefile Automation Reference

The project includes a self-documenting `Makefile` to simplify building, testing, and cleaning.

* **`make all`** (Default): Triggers the report generation target.
* **`make setup`**: Executes `scripts/setup_env.sh` to verify system dependencies.
* **`make report`**: Runs `scripts/generate_report.sh` to compile reports in `output/`.
* **`make test`**: Runs the automated test suite across all sample logs, validating successful execution (Exit 0) and expected failure catching (Exit 1).
* **`make clean`**: Cleans up and removes all generated reports from the `output/` directory.
* **`make help`**: Parses the Makefile using `awk` and prints all available targets with descriptions.
