# RISC-V Log Analyzer

A robust, shell-based tool designed to process RISC-V simulation log files, extract critical execution metrics, and generate summary reports. This project serves as a comprehensive automation pipeline utilizing Linux command-line utilities, rigorous shell scripting (`bash`), advanced Git workflows, and Makefile automation.

---

## Project Directory Structure

```text
riscv-log-analyzer/
├── README.md
├── Makefile
├── .gitignore
├── scripts/
│   ├── analyze.sh
│   ├── setup_env.sh
│   └── generate_report.sh
├── test_data/
│   ├── sample_sim.log
│   ├── sample_pass.log
│   └── sample_fail.log
├── output/ (gitignored)
└── docs/
    └── USAGE.md
